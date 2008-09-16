export MONITOR_PLUGINS=$MONITOR_HOME/plugins

############################################################################
# get_value_from_file
#############################################################################
# read a value from a file, if it does not exist set it to the default value
#  of zero.

get_value_from_file()
{
  defaultValue=$2

  if [ -f $1 ] ; then
    cat $1
  else
    if [ "x$defaultValue" = "x" ] ; then
      echo 0
    else
      echo $defaultValue
    fi;
  fi;
}

############################################################################
# get_tomcat_entry
#############################################################################
# Find the tomcat entry that matches the specified name.
#
get_tomcat_entry() {
  name=$1
  ret=1

  #echo "looking for $name ret=$ret";

  entry=$(get_tomcat_entries | grep $name)

  if [ $? -ne 0 ] ; then
    return 1
  fi;

  parse_jvm_entry "$entry"; 
  
}

############################################################################
# get_tomcat_entries
#############################################################################
# Read the tomcat entries that are not comments.
#
get_tomcat_entries() {
  grep -v ' *#' $TOMCAT_TAB
}

############################################################################
# parse_jvm_entry
#############################################################################
# Parse a JVM entry and populate env vars with the entry values
#
parse_jvm_entry() {
  entry=$1

  export JVM_NAME=`echo "$entry" | cut -d: -f 1`
  export JVM_TOMCAT_USER=`echo "$entry" | cut -d: -f 2`
  export JVM_TOMCAT_HOME=`echo "$entry" | cut -d: -f 3`
  export JVM_HTTP_PORT=`echo "$entry" | cut -d: -f 4`
  export JVM_SHUTDOWN_PORT=`echo "$entry" | cut -d: -f 5`
  export JVM_AJP_PORT=`echo "$entry" | cut -d: -f 6`
  export JVM_TEST_URI=`echo "$entry" | cut -d: -f 7`
  export JVM_TEST_TEXT=`echo "$entry" | cut -d: -f 8`
  export JVM_OPTS=`echo "$entry" | cut -d: -f 9`

}


# read the tomcat entries
test_entries() {
  get_tomcat_entries | while read entry
  do
    echo "entry=$entry"
    parse_jvm_entry "$entry"

    echo JVM_NAME: $JVM_NAME
    echo JVM_TOMCAT_USER: $JVM_TOMCAT_USER
    echo JVM_TOMCAT_HOME: $JVM_TOMCAT_HOME
    echo JVM_HTTP_PORT: $JVM_HTTP_PORT
    echo JVM_SHUTDOWN_PORT: $JVM_SHUTDOWN_PORT
    echo JVM_AJP_PORT: $JVM_AJP_PORT
    echo JVM_OPTS:     $JVM_OPTS
    echo JVM_TEST_URI: $JVM_TEST_URI
    echo JVM_TEST_TEXT: $JVM_TEST_TEXT

  done;
  exit;
}

############################################################################
# execPluginScripts
#############################################################################
# Examine the plugin directory and execute anything specified.
#
execPluginScripts() {
  dir=$1
  prefix=$2
  shift 2
  args=$*
  scripts=`eval ls ${dir}/${prefix}* 2> /dev/null`

  for script in $scripts 
  do
    if [ -x $script ] ; then
      echo "  Execute $script $args .."
      eval $script $args
    fi;  
  done;
}


############################################################################
# appPluginPostStart
#############################################################################
# Examine the plugin directory and start anything specified there that
#   needs to be started before the app starts. 
#
appPluginPostStart() {
  execPluginScripts $MONITOR_PLUGINS/app/startup "POST-" $* 
}

############################################################################
# appPluginPreStart
#############################################################################
# Examine the plugin directory and start anything specified there that
#   needs to be started before the app starts. 
#
appPluginPreStart() {
  execPluginScripts $MONITOR_PLUGINS/app/startup "PRE-" $*
}

############################################################################
# appPluginPostShutdown
#############################################################################
# Examine the plugin directory and start anything specified there that
#   needs to be shutdown after a app shutsdown. 
#
appPluginPostShutdown() {
  execPluginScripts $MONITOR_PLUGINS/app/shutdown "POST-" $*
}

############################################################################
# appPluginPreShutdown
#############################################################################
# Examine the plugin directory and shutdown anything specified there that
#   needs to be shutdown before a app shutsdown. 
#
appPluginPreShutdown() {
  execPluginScripts $MONITOR_PLUGINS/app/shutdown "PRE-" $*
}

############################################################################
# jvmPluginPostStart
#############################################################################
# Examine the plugin directory and start anything specified there that
#   needs to be started before the jvm starts. 
#
jvmPluginPostStart() {
  execPluginScripts $MONITOR_PLUGINS/jvm/startup "POST-" $* 
}

############################################################################
# jvmPluginPreStart
#############################################################################
# Examine the plugin directory and start anything specified there that
#   needs to be started before the jvm starts. 
#
jvmPluginPreStart() {
  execPluginScripts $MONITOR_PLUGINS/jvm/startup "PRE-" $*
}

############################################################################
# jvmPluginPostShutdown
#############################################################################
# Examine the plugin directory and start anything specified there that
#   needs to be shutdown after a jvm shutsdown. 
#
jvmPluginPostShutdown() {
  execPluginScripts $MONITOR_PLUGINS/jvm/shutdown "POST-" $*
}

############################################################################
# jvmPluginPreShutdown
#############################################################################
# Examine the plugin directory and shutdown anything specified there that
#   needs to be shutdown before a jvm shutsdown. 
#
jvmPluginPreShutdown() {
  execPluginScripts $MONITOR_PLUGINS/jvm/shutdown "PRE-" $*
}

