#!/bin/bash

unset http_proxy

. /etc/monitor_tomcat.conf
. $MONITOR_HOME/monitor_tomcat_funcs.sh

export MONLOG=$MONITOR_HOME/monitor_multi_jvms.log

trap 'rm -f $LOCK_FILE; echo "Aborting monitor_tomcat.sh"; exit' 1 2 3 15

############################################################################
# monitor_tomcat.sh
############################################################################
# This script watches multiple tomcat JVMS to sense errors. If it
#   detects out of memory JVM errors it will re-start the appriopriate
#   JVM. Note this script works in conjuction with the
#   /etc/init.d/apache script and it must be run by root. If the apache
#   app server is taken down, the script will not try to restart the app
#   server.
#
# The script reads the /etc/tomcat-jvm-tab to determine which JVMs to
#   monitor.
#


############################################################################
# restart_tomcat
#############################################################################
# Restart the tomcat instance specified by the TOMCAT_HOME
#
restart_tomcat() {
  TOMCAT_USER=$1
  export TOMCAT_HOME=$2
  JVM=$3
  export CATALINA_HOME=$TOMCAT_HOME
  export CATALINA_BASE=$TOMCAT_HOME
  export CATALINA_PID=$TOMCAT_HOME/logs/tomcat.pid

  if [ -d $TOMCAT_HOME ] ; then
    if [ -f $CATALINA_PID ] ; then
      pid=`cat $CATALINA_PID`
      ofiles=`$LSOF -p $pid | wc -l`

      echo "`date`: Tomcat $pid has $ofiles files open" >> $MONLOG
      kill -3 $pid
    fi;

    #sudo -u $TOMCAT_USER "$MONITOR_HOME/shutdown.sh"
    "$MONITOR_HOME/shutdown.sh"
    sleep 2

    if [ -f $CATALINA_PID ] ; then
      pid=`cat $CATALINA_PID`
      kill $pid
      kill -9 $pid
    fi;

    "$MONITOR_HOME/startup.sh"
    #sudo -u  $TOMCAT_USER "$MONITOR_HOME/startup.sh"
    #su $TOMCAT_USER -c "cd $TOMCAT_HOME; bin/startup.sh"
    #su $TOMCAT_USER -c "$TRIALS_HOME/multi-jvm/start.sh $TOMCAT_HOME"
    echo "`date`:Tomcat JVM $TOMCAT_HOME started" >> $MONLOG
  else
    echo "`data`:$TOMCAT_HOME does not exist!" >> $MONLOG
  fi;
}

do_wget() {
  if [ "X$HTTP_USER" = "X" ] ; then
    echo $WGET $*
    $WGET $*
  else
    echo $WGET --http-user=$HTTP_USER $*
    $WGET --http-user=$HTTP_USER --http-password=$HTTP_PASSWORD $*
  fi;
}

############################################################################
# check_tomcat
#############################################################################
# Check the tomcat test URI to see if it responds
#
check_tomcat() {
  JVM=$1
  JVM_HTTP_PORT=$2
  TEST_URI=$3
  TEST_TEXT=$4
  site_not_responding=1
  typeset -i retries
  retries=3

  url="http://127.0.0.1:${JVM_HTTP_PORT}${TEST_URI}"
  outfile=$TMPDIR/site.html

  while [ $retries -gt 0 -a $site_not_responding -ne 0 ]
  do
    retries=$retries-1;

    rm -f $outfile

    do_wget --tries=1 --output-document=$outfile --timeout=10 $url

    grep "$TEST_TEXT" $outfile > /dev/null

    if [ $? -ne 0 ] ; then
      echo "`date`: Warning! The jvm $JVM is not responding" >> $MONLOG
      site_not_responding=1;
      sleep 1;
    else
      site_not_responding=0;
    fi;

  done;

  if [ $site_not_responding -ne 0 ] ; then
    cp $outfile $TMPDIR/site-crash.html
    echo "`date`: retries=$retries site_not_responding=$site_not_responding" >> $MONLOG
    echo "`date`: $url" >> $MONLOG
    echo "`date`: Doh! The jvm $JVM is not responding" >> $MONLOG
  fi;

  return $site_not_responding
}

check_for_out_of_memory() {
  tomcatlog=$1;  

  errorFound=0;

  # Check the tomcat logs for out of memory exceptions
  loglenfile=$TMPDIR/tc-${jvm}-loglen.txt

  # find out what byte we last scanned the file from
  oldpos=`get_value_from_file $loglenfile 1`
  if [ -f $tomcatlog ] ; then
    stat --format="%s" $tomcatlog > $loglenfile  
  else
    echo 0 > $loglenfile
  fi;

  newpos=`get_value_from_file $loglenfile 1`

  diffpos=`expr $newpos - $oldpos`
  if [ $diffpos -gt 10 ] ; then
    echo $MONITOR_HOME/filePortion.perl $tomcatlog $oldpos 
    $MONITOR_HOME/filePortion.perl $tomcatlog $oldpos | grep "OutOfMemoryError"
    if [ $? -eq 0 ] ; then
      echo "WARNING OutOfMemoryError found!";
      errorFound=1;
    fi; # $? -eq 0
  fi; # $diffpos -gt 10

  return $errorFound;
}


mkdir -p $TMPDIR

if [ -f $LOCK_FILE ] ; then
  kill `cat $LOCK_FILE`
  kill -9 `cat $LOCK_FILE`

  rm -f $LOCK_FILE
fi;


sleep $WATCH_SLEEP
sleep $WATCH_SLEEP

# This script peridiocally touches the jvm_watch file. If we remove the
#   file and it pops back into existence, we know another instance of the
#   script is running.

if [ -f $LOCK_FILE ] ; then
  echo "monitor_tomcat.sh already running! aborting!"
  exit 0;
fi;

echo "`date`: Monitor Jvms Started" >> $MONLOG

typeset -i rcheck
rcheck=-3

# Monitor Tomcat forever until the script dies.
while [ 1 ]
do
  # update the lock file
  echo $$ > $LOCK_FILE

  last_check=`expr \( $rcheck \* $WATCH_SLEEP \)`
  rcheck=$rcheck+1
  do_web_check=0
  do_apache_check=0

  if [ $last_check -gt 59 ] ; then
    rcheck=0
    do_web_check=1;
    do_apache_check=1;
  fi;

  get_tomcat_entries | while read entry
  do
    parse_jvm_entry "$entry"

    jvm=$JVM_NAME
    catalina_pid=$JVM_TOMCAT_HOME/logs/tomcat.pid

    if [ -f $catalina_pid ] ; then
      # monitor_tomcat is currently maanging this active tomcat instance
      # e.g. the instance has not been stopped by this script.

      echo Watching $jvm

      if [ $do_web_check -eq 1 ] ; then
        #echo check_tomcat $JVM_NAME $JVM_HTTP_PORT $JVM_TEST_URI $JVM_TEST_TEXT >> $MONLOG
        check_tomcat $JVM_NAME $JVM_HTTP_PORT $JVM_TEST_URI $JVM_TEST_TEXT
        if [ $? -ne 0 ] ; then
          restart_tomcat $JVM_TOMCAT_USER $JVM_TOMCAT_HOME $JVM_NAME
          rcheck=-15
          do_apache_check=0;
          continue; # skip the rest of this loop iteration
        fi;
      fi; # not responding to http

      tomcatlog=$JVM_TOMCAT_HOME/logs/catalina.out
      check_for_out_of_memory $tomcatlog

      if [ $? -ne 0 ] ; then
         # we have sensed an out of memory error, let's restart
         # the JVM
         echo "`date`: Detected out of memory errors in $jvm" >> $MONLOG
         echo "`date`: Restarting tomcat $jvm" >> $MONLOG
         #tail -100 $tomcatlog >> $JVM_TOMCAT_HOME/logs/catalina-mem.out
         rm -f $tomcatlog

         restart_tomcat $JVM_TOMCAT_USER $JVM_TOMCAT_HOME $JVM_NAME
         do_apache_check=0;
         continue;
      fi; # out of memory error detected
    fi;   # catalina_pid exists
    
  done;

  ###################################################################
  # Make sure the app server processes are running
  ###################################################################

  # look for java processes running
  ps -ef | grep -v grep | grep java > /dev/null
  java_not_running=$?

  if [ $APACHE_ENABLE_CHECK -eq 1 ] ; then
    ps -ef | grep -v grep | grep http > /dev/null
    http_not_running=$?
  else
    http_not_running=0;
  fi;


  ###################################################################
  # Try to connect to the web server and see if we can bring down a page
  ###################################################################

  site_not_responding=0

  apacheRes=$TMPDIR/apache-site.html

  if [ $APACHE_ENABLE_CHECK -eq 0 ] ; then
     do_apache_check=0;
  fi;

  if [ $do_apache_check -eq 1 ] ; then
    rm -f $apacheRes
    echo $WGET --tries=1 --output-document=$apacheRes --timeout=25 $APACHE_TEST_URL
    $WGET --tries=1 --output-document=$apacheRes --timeout=25 $APACHE_TEST_URL
    grep "$APP_TEST_TEXT" $apacheRes > /dev/null
    if [ $? -ne 0 ] ; then
      echo "`date`: Doh! The server is not responding" >> $MONLOG
      site_not_responding=1;
    fi;

    # TODO: This check may be proquest specific
    grep "There has been an Error." $apacheRes > /dev/null
    if [ $? -eq 0 ] ; then
      echo "`date`: Doh! The server is not responding" >> $MONLOG
      site_not_responding=1;
    fi;

    #rm -f $apacheRes
  fi;

  if [ $java_not_running -ne 0 ] ; then
     if [ -e $APP_INIT_SCRIPT ] ; then
       echo "`date`: Restarting application" >> $MONLOG
       $APP_INIT_SCRIPT restart
     else
       echo "`date`: WARNING App should be restarted but APP_INIT_SCRIPT=$APP_INIT_SCRIPT does not exist!" >> $MONLOG
     fi;
  fi;

  if [ $http_not_running -ne 0 -o $site_not_responding -ne 0  ] ; then
     #cp $LOGDIR/gc.log $LOGDIR/gc-crash-`date +%Y%m%d`.log

     if [ -e $APACHE_INIT_SCRIPT ] ; then
       echo "`date`: Restarting apache" >> $MONLOG
 
       $APACHE_INIT_SCRIPT restart
     else
       echo "`date`: WARNING apache should be restarted but APACHE_INIT_SCRIPT=$APACHE_INIT_SCRIPT does not exist!" >> $MONLOG
     fi;
  fi;

  sleep $WATCH_SLEEP

done;

rm -f $LOCK_FILE

