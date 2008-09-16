#!/bin/bash

. /etc/monitor_tomcat.conf
. $MONITOR_HOME/monitor_tomcat_funcs.sh

get_tomcat_entries | while read entry
do
   parse_jvm_entry "$entry";

   echo $JVM_NAME $JVM_TOMCAT_USER $JVM_TOMCAT_HOME
done;
