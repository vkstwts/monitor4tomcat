#!/bin/bash

home=$1

if [ "x$home" = "x" ] ; then
  home=/usr/local/monitor_tomcat
fi;

export MONITOR_HOME=$home
export MONITOR_USER=root
export MONITOR_GROUP=root
export PLUGINS=$MONITOR_HOME/plugins

mkdir -p $MONITOR_HOME

installFile() {
  install --group=$MONITOR_GROUP --owner=$MONITOR_USER --mode=$1 $2 $3
}

findJavaHome() {
    echo "/etc/java.conf does not exist. Try to create one";

    # try to look for JAVA
    echo "Searching for java (this may take a while) ..";
    javas=`locate java | grep -e "^/usr.*bin/java$"`

    if [ ! "x$javas" = "x" ] ; then
      myjava="";

      while [ "x$myjava" = "x" ] ;
      do
        echo "Please select your preferred Java binary:";
        echo "";
        set -i idx;
        idx=1;
        for java in $javas
        do
          jvm[$idx]=$java
          echo "  $idx ) $java";
        
          ((idx = idx + 1 ));
        done;

        printf "\njava : <default=1>  "
        read x;

        myjava=${jvm[${x=1}]};
      done;

      if [[ $myjava =~ '(.*)/bin/java' ]] ; then
        export JAVA_HOME=${BASH_REMATCH[1]};
      fi;
    fi;
}

writeJavaConf() {

cat > /etc/java.conf <<EOF
pathmunge () {
        if ! echo \$PATH | /bin/egrep -q "(^|:)\$1(\$|:)" ; then
           if [ "\$2" = "after" ] ; then
              PATH=\$PATH:\$1
           else
              PATH=\$1:\$PATH
           fi
        fi
}

export JAVA_HOME=$JAVA_HOME
pathmunge \$JAVA_HOME/bin
EOF

}

installFile 755 monitor_tomcat.sh $MONITOR_HOME
installFile 755 monitor_tomcat_funcs.sh $MONITOR_HOME
installFile 755 filePortion.perl $MONITOR_HOME
installFile 755 lsjvms.sh $MONITOR_HOME


installFile 755 shutdown.sh $MONITOR_HOME
installFile 755 startup.sh $MONITOR_HOME

# check for /etc/java.conf 

if [ ! -f /etc/java.conf ] ; then
  # create an /etc/java.conf file

  # check the JAVA_HOME
  if [ ! -d "$JAVA_HOME" ] ; then
    findJavaHome;
  fi;

  if [ ! "x$JAVA_HOME" = "x" ] ; then
    if [ -d $JAVA_HOME ] ; then
      writeJavaConf;
    fi;
  fi;
 
  if [ ! -f /etc/java.conf ] ; then
    echo "ERROR: Cannot find java installed.";
    echo "ERROR: Either install java and try again or ..";
    echo "ERROR:   create the /etc/java.conf file by hand.";    
  fi;
fi;


if [ ! -f /etc/tomcat-jvm-tab ] ; then
  installFile 644 example/tomcat-jvm-tab /etc/
  echo "INFO: edit /etc/tomcat-jvm-tab to match your environment";
fi;

if [ ! -f /etc/monitor_tomcat.conf ] ; then
  installFile 644 example/monitor_tomcat.conf /etc/
  echo "INFO: edit /etc/monitor_tomcat.conf to match your environment";
fi;

if [ ! -d $PLUGINS ] ; then
  mkdir -p $PLUGINS
  mkdir -p $PLUGINS/jvm/startup
  mkdir -p $PLUGINS/jvm/shutdown
  mkdir -p $PLUGINS/app/startup
  mkdir -p $PLUGINS/app/shutdown

  echo "INFO: consider adding Monitor4Tomcat plugins to $PLUGINS";
fi;

echo "INFO: create a /etc/init.d/jvmmon script to match your environment";


