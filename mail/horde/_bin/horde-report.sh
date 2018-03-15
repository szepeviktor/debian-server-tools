#!/bin/bash
#
# List log items above NOTICE severity of the Horde Log.
#
# VERSION       :0.1.2
# DATE          :2018-02-24
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install logtail
# LOCATION      :/usr/local/bin/horde-report.sh

# Extract log levels
#
#     sed -n -e 's|\s*const \(\S\+\) = .*|\1|p' /home/horde/website/pear/php/Horde/Log.php | paste -s -d "|"
#
# Adding cron job
#
#     59 *	* * *	horde	/usr/local/bin/horde-report.sh /home/horde/website/log
#
# Last minute tries to make sure there is a new log file at 00:59.

declare -r HORDE_LEVELS="EMERG|EMERGENCY|ALERT|CRIT|CRITICAL|ERR|ERROR|WARN|WARNING|NOTICE"
declare -r -i EXTRA_LINES="0"

# Log directory
LOG_PATH="$1"

set -e

test -d "$LOG_PATH"

# Log file
HORDE_LOG="${LOG_PATH}/horde.log"

# No log yet
test -f "$HORDE_LOG" || exit 0

# Take new lines, limit at 5 MB and look for errors
/usr/sbin/logtail2 "$HORDE_LOG" \
    | grep -v -E '^[0-9T:+-]{25} NOTICE: HORDE (Guest user is not authorized for|\[[a-z]+\] Login success for|\[[a-z]+\] User \S+ logged out of)' \
    | grep -v -E '^[0-9T:+-]{25} WARN: HORDE \S+ PHP ERROR: Declaration of .* should be compatible with Horde_' \
    | dd iflag=fullblock bs=1M count=5 2> /dev/null \
    | grep -E -A "$EXTRA_LINES" "^[0-9T:+-]{25} (${HORDE_LEVELS}):" \
    || if [ "$?" -ne 1 ]; then
        # This is a real error, 1 is "not found"
        exit 102
    fi

exit 0
