Monitor4Tomcat
====

Monitor4Tomcat is a set of scripts that can be used to restart Tomcat when exceptions or other errors have occurred in the application.

### 1.0 INTRODUCTION

author: rseward@bluestone-consulting.com

Written by Rob Seward of the Bluestone Consulting Group, LLC.

  http://www.bluestone-consulting.com/

Bluestone provides Professional Support Services for this monitoring 
software. Please contact us if you are interested in Support Services
for these monitoring scripts.

A quick and dirty system for monitoring multiple tomcat instances on UNIX.

The script will check for OutOfMemory exceptions in the logs and sample
pages from tomcat to make sure the application is servicing requests.

If a problem occurs the monitor can stop / start the tomcat JVM and / or the
entire application.

The monitor requires bash and perl to run. It should run in most Linux / UNIX
environments.

### 2.0 INSTALL

Determine your location for the tomcat_monitor runtime directory. I suggest 
/usr/local/tomcat_monitor. Untar the scripts into a staging directory.

`  tar -xvzf tomcat_monitor-0.2.tar.gz `

Run the deploy script as root with the location of the runtime directory.
 
```sh
  cd tomcat_monitor
  sudo ./deploy.sh /usr/local/tomcat_monitor
```

### 3.0 CONFIGURATION

#### 3.1 /etc/java.conf

The /etc/java.conf stores the location of `JAVA_HOME` and adds `JAVA_HOME` to
the `PATH`. See `example/java.conf` for an example file. 

In normal circumstances the deploy.sh should detect your java and create a
`/etc/java.conf` for you.

#### 3.2 /etc/tomcat-jvm-tab

The `tomcat-jvm-tab` file defines all the tomcat JVMS you wish Tomcat Monitor
to start / stop / monitor for you.

Here is an example of the format of the file. There will be one line in the 
file per JVM to be monitored. 

```sh
  #########################################################################
  # tomcat-jvm-tab
  #########################################################################
  # List all jvms running on the server
  #
  # jvm-name=Name of the JVM to differientiate if from other JVMs.
  # user=Unix User who owns the Tomcat process
  # tomcat-home=Home directory for this Tomcat instance.
  # web-port=HTTP connector port of the instance.
  # shutdown-port=Tomcat shutdown port for the instance.
  # test-uri=Test URI available on the web-port to verify the instance is 
  #           serving requests
  # test-string=Text to find in the HTML returned by the test-uri
  # ajp-port=Tomcat AJP Port for the instance
  # jvm_opts=Additional JVM options to be used to start the instance. Place 
  #           your Java JVM memory settings go here.
  #
  #jvm-name:tomcat-home:web-port:shutdown-port:ajp-port:test-uri:jvm-opts
  rseward:rseward:/bluestone/apache-tomcat-5.5.17:8080:8005:8009:/noplace/index.html:noPlace.com:-server -Xmx128m:
```

#### 3.3 `/etc/init.d/jvmmon` (or your preferred name)

  Copy the `init.d/jvmmon` script to `/etc/init.d` and customize it to match your application.

#### 3.4 `/etc/monitor_tomcat.conf`

  Change the `MONITOR_HOME` to match the Tomcat Monitor runtime directory.

  Edit `APP_INIT_SCRIPT` to match your application's jvmmon `init.d` script.

  Edit `WATCH_SLEEP` if you require the monitor to check the JVMS less or 
    more often.

##### 3.4.1 Monitor Apache

  Edit APACHE_ENABLE_CHECK if you use Apache with your application and
    want to monitor httpd along with Tomcat by this script.

  Edit APACHE_INIT_SCRIPT if you are monitoring Apache with this script 
    frame work.

  Edit APACHE_TEST_URL for an Apache URL to sample.

  Edit APACHE_TEST_TEXT for a string to find in the HTML returned by
    APACHE_TEST_TEXT. If this string is not found in three attempts
   the script will restart apache. 

```sh
  ###########################################################################
  # monitor_tomcat.conf
  ###########################################################################
  # Used by tomcat_monitor scripts for configuration variables.

  . /etc/java.conf

  export MONITOR_HOME=/usr/local/monitor_tomcat
  export WATCH_SLEEP=15
  export TMPDIR=/root/tmp

  export APACHE_ENABLE_CHECK=0;
  export APP_INIT_SCRIPT=/etc/init.d/jvmmon
  export APACHE_INIT_SCRIPT=/etc/init.d/jvmmon
  export APACHE_TEST_TEXT=noPlace.com
  export APACHE_TEST_URL=http://127.0.0.1/

  export PIDFILE=/var/run/monitor_tomcat.pid
  export LOCK_FILE=$PIDFILE
  export WGET=/usr/bin/wget 
  export TOMCAT_TAB=/etc/tomcat-jvm-tab
  export LSOF=/usr/sbin/lsof
  export TOMCAT_REMOVE_LOGS_ON_START=0
```

### 4.0 RUNNING

Tomcat Monitor will run continously, sleeping for $WATCH_SLEEP seconds at a
time while it is not monitoring jvms. When the monitor wakes, it: 
  - samples JVM HTTP ports
  - checks JVM logs for OutOfMemory exceptions
  - samples Apache URL (if configured)

Should a sample not contain a specified Text string three times in a row, the
monitor will restart the failing JVM instance (or Apache).

If a log contains OutOfMemory the JVM instance will be restarted immediately.


### 4.1 Run by hand

  If you would like to observe monitor_tomcat at work.

```sh
    sudo bash
    cd $MONITOR_HOME
    ./monitor_tomcat.sh
```

### 4.2 Run as service

  To run Tomcat Monitor as a service you must create an init.d script to
  start / stop the monitor. See init.d/jvmmon for a sample init.d script.

  This script should start the JVMs that are monitored and the Tomcat Monitor.


