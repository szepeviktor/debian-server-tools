#!/bin/bash
#
# List log items above NOTICE severity of the Laravel log.
#
# VERSION       :0.2.3
# DATE          :2016-09-22
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install logtail
# LOCATION      :/usr/local/bin/laravel-report.sh

# Set log rotation in .env
#
#     APP_ENV=production
#     APP_LOG=daily
#
# Adding cron job
#
#     59 *	* * *	USER	/usr/local/bin/laravel-report.sh /home/USER/website/code/storage/logs/
#
# Last minute tries to make sure there is a new log file at 00:59.

declare -r MONOLOG_LEVELS="NOTICE|WARNING|ERROR|CRITICAL|ALERT|EMERGENCY"
declare -r -i EXTRA_LINES="3"

set -e

# Log directory
LOG_PATH="$1"
test -d "$LOG_PATH"

# Today's log file
LARAVEL_LOG="${LOG_PATH}/laravel-$(date "+%Y-%m-%d").log"

# No log yet
test -f "$LARAVEL_LOG" || exit 0

# Take new lines, limit at 5 MB and look for errors
/usr/sbin/logtail2 "$LARAVEL_LOG" \
    | dd iflag=fullblock bs=1M count=5 2> /dev/null \
    | grep -E -A "$EXTRA_LINES" "^\\[[0-9]{4}-.+ production\\.(${MONOLOG_LEVELS}):" \
    || if [ $? != 1 ]; then
        # This is a real error, 1 is "not found"
        exit 102
    fi

exit 0
