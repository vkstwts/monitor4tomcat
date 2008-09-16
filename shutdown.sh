#!/bin/bash

##############################################################################
# shutdown.sh
##############################################################################
# This script is used to stop the invidual JVMS that are being monitored 
# 

. /etc/monitor_tomcat.conf
. $MONITOR_HOME/monitor_tomcat_funcs.sh

inJvm=$1

# get the tomcat_dir from /etc/tomcat-jvm-tab
if [ "x$inJvm" = "x" ] ; then
  # shutting down all JVMS listed in tab
  tomcat_jvms=$(cat /etc/tomcat-jvm-tab | grep -v "^#" | cut -d : -f 3)
else
  # shutting down a named JVM
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

  parent_dir=`dirname $TOMCAT_HOME`

  cd $parent_dir
  cd $TOMCAT_HOME

  jvmPluginPreShutdown $TOMCAT_HOME

  bin/shutdown.sh

  if [ -f $CATALINA_PID ] ; then
    sleep 2
    kill `cat $CATALINA_PID`
    kill -9 `cat $CATALINA_PID`
    rm -f $CATALINA_PID
  fi;

  jvmPluginPostShutdown $TOMCAT_HOME 

done
