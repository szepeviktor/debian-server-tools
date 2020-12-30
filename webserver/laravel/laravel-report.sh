#!/bin/bash
#
# List Laravel log items above NOTICE severity and check for failed queue jobs.
#
# VERSION       :0.4.1
# DATE          :2020-08-04
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
#     59 *	* * *	USER	/usr/local/bin/laravel-report.sh /home/USER/website/code
#
# Last minute tries to make sure there is a new log file at 00:59.

declare -r MONOLOG_LEVELS="NOTICE|WARNING|ERROR|CRITICAL|ALERT|EMERGENCY"
declare -r -i EXTRA_LINES="5"

# Environment name
LARAVEL_ENV="production"
#LARAVEL_ENV="staging"

set -e -o pipefail

# Laravel directory
LARAVEL_PATH="$1"

test -d "$LARAVEL_PATH"
test -x "${LARAVEL_PATH}/artisan"

# Check for failed queue jobs
if ! "${LARAVEL_PATH}/artisan" queue:failed | grep -q -F 'No failed jobs!'; then
    "${LARAVEL_PATH}/artisan" queue:failed 1>&2
    exit 101
fi

# Today's log file
LARAVEL_LOG="${LARAVEL_PATH}/storage/logs/laravel-$(date "+%Y-%m-%d").log"

# No log yet
test -f "$LARAVEL_LOG" || exit 0

# Take new lines, limit at 5 MB and look for errors
/usr/sbin/logtail2 "$LARAVEL_LOG" \
    | dd iflag=fullblock bs=1M count=5 2> /dev/null \
    | tr '\000' '?' \
    | grep -E -A "$EXTRA_LINES" "^\\[[0-9]{4}-.+ ${LARAVEL_ENV}\\.(${MONOLOG_LEVELS}):" \
    | fold --width=623 --spaces \
    || if [ "$?" != 1 ]; then
        # This is a real error, 1 is "not found"
        exit 102
    fi

exit 0
