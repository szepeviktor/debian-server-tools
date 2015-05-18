#!/bin/bash --version
#
# LSB init script for interpreted scripts using start-stop-daemon
# @TODO LSB init script for executables
#
# VERSION       :0.1
# UPSTREAM      :https://gist.github.com/bcap/5397674
# REFS          :http://refspecs.linuxbase.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/tocsysinit.html
# DOCS          :https://wiki.debian.org/LSBInitScripts

# Installation
#
# cp lsb-init-script.tpl /etc/init.d/<SERVICE-NAME>
# editor /etc/init.d/<SERVICE-NAME>
# update-rc.d <SERVICE-NAME> defaults

#!/bin/bash
### BEGIN INIT INFO
# Provides:          <SERVICE-NAME>
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: <SERVICE-DESCRIPTION>
### END INIT INFO

PATH="/sbin:/usr/sbin:/bin:/usr/bin"
DESC="<SERVICE-DESCRIPTION>"
NAME="<SERVICE-NAME>"
DAEMON="/usr/bin/script.py"
DAEMON_ARGS="-c /etc/service-name/config.ini"

WORK_DIR="/var/lib/${NAME}"
USER="${NAME}"
GROUP="${NAME}"
PIDFILE="/var/run/${NAME}.pid"
SCRIPTNAME="/etc/init.d/${NAME}"

# Run as root
START_STOP_DAEMON_OPTIONS="--chdir=${WORK_DIR}"
# Run as a user
#START_STOP_DAEMON_OPTIONS="--chuid=${USER}:${GROUP} --chdir=${WORK_DIR}"
# Add --background to force forking

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/${NAME} ] && . /etc/default/${NAME}

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start() {
  # Return
  #   0 if daemon has been started
  #   1 if daemon was already running
  #   2 if daemon could not be started
  start-stop-daemon ${START_STOP_DAEMON_OPTIONS} --start --quiet --pidfile "$PIDFILE" \
    --exec "$DAEMON" --test || return 1
  start-stop-daemon ${START_STOP_DAEMON_OPTIONS} --start --quiet --pidfile "$PIDFILE" \
    --exec "$DAEMON" -- ${DAEMON_ARGS} || return 2
}

#
# Function that stops the daemon/service
#
do_stop() {
  # Return
  #   0 if daemon has been stopped
  #   1 if daemon was already stopped
  #   2 if daemon could not be stopped
  #   other if a failure occurred
  start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile "$PIDFILE"
  RETVAL="$?"
  [ "$RETVAL" == 2 ] && return 2
  rm -f "$PIDFILE"
  return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
  start-stop-daemon --stop --quiet --pidfile "$PIDFILE" --signal 1 --name "$NAME"
  return 0
}

case "$1" in

  start)
    [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
    do_start
    case "$?" in
      0|1)
        [ "$VERBOSE" != no ] && log_end_msg 0
      ;;
      2)
        [ "$VERBOSE" != no ] && log_end_msg 1
      ;;
    esac
  ;;

  stop)
    [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
    do_stop
    case "$?" in
      0|1)
        [ "$VERBOSE" != no ] && log_end_msg 0
      ;;
      2)
        [ "$VERBOSE" != no ] && log_end_msg 1
      ;;
    esac
  ;;

  status)
    status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
  ;;

  #reload|force-reload)
  #
  # If do_reload() is not implemented then leave this commented out
  # and leave 'force-reload' as an alias for 'restart'.
  #
  #  log_daemon_msg "Reloading $DESC" "$NAME"
  #  do_reload
  #  log_end_msg $?
  #;;

  restart|force-reload)
    #
    # If the "reload" option is implemented then remove the
    # 'force-reload' alias
    #
    log_daemon_msg "Restarting $DESC" "$NAME"
    do_stop
    case "$?" in
      0|1)
        do_start
        case "$?" in
          0)
            log_end_msg 0
          ;;
          # Old process is still running
          1)
            log_end_msg 1
          ;;
          # Failed to start
          *)
            log_end_msg 1
          ;;
        esac
      ;;
      *)
        # Failed to stop
        log_end_msg 1
      ;;
    esac
  ;;

  *)
    #
    # If the "reload" option is implemented then comment this out
    #
    #echo "Usage: $SCRIPTNAME {start|stop|status|restart|reload|force-reload}" >&2
    echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
    exit 3
  ;;

esac

exit 0
