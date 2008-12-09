#!/bin/bash

##############################################################################
# startup.sh
##############################################################################
# This script is used to start the invidual JVMS that are being monitored 

. /etc/monitor_tomcat.conf
. $MONITOR_HOME/monitor_tomcat_funcs.sh

inJvm=$1

# get the tomcat_dir from /etc/tomcat-jvm-tab
if [ "x$inJvm" = "x" ] ; then
  # start all JVMS listed in the tab
  tomcat_jvms=$(cat /etc/tomcat-jvm-tab | grep -v "^#" | cut -d : -f 3)
else
  # start a single named JVM
  tomcat_jvms=$(cat /etc/tomcat-jvm-tab | grep $inJvm | grep -v "^#" | cut -d : -f 3)
fi;


for jvm in $tomcat_jvms
do
  entry=`get_tomcat_entries | grep $jvm`
  parse_jvm_entry "$entry"

  export TOMCAT_HOME=$JVM_TOMCAT_HOME
  export CATALINA_HOME=$TOMCAT_HOME
  export CATALINA_BASE=$TOMCAT_HOME
  export CATALINA_PID=$TOMCAT_HOME/logs/tomcat.pid
  export JAVA_OPTS=$JVM_OPTS
  parent_dir=`dirname $TOMCAT_HOME`

  cd $parent_dir
  cd $TOMCAT_HOME

  jvmPluginPreStart $TOMCAT_HOME

  if [ ${TOMCAT_REMOVE_LOGS_ON_START=0} -ne 0 ] ; then
      rm -f logs/*
  fi;

  if [ -f $CATALINA_PID ] ; then
    # kill an existing tomcat instance if any
    kill `cat $CATALINA_PID`
    sleep 2
    kill -9 `cat $CATALINA_PID`
    rm -f $CATALINA_PID
  fi;

  if [ "x$JVM_TOMCAT_USER" = "x" ] ; then
    bin/startup.sh
  else
    #echo su -c bin/startup.sh $JVM_TOMCAT_USER
    #su  -c bin/startup.sh $JVM_TOMCAT_USER
    # TODO: make the selection of sudo/su strategy dynmanic
    # TODO:  ubuntu/rhel/fedora all need different strategies
    echo sudo -E -u $JVM_TOMCAT_USER `pwd`/bin/startup.sh
    sudo -E -u $JVM_TOMCAT_USER $TOMCAT_HOME/bin/startup.sh
  fi;

  jvmPluginPostStart $TOMCAT_HOME

done
