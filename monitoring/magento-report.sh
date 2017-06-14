#!/bin/bash
#
# List log items above NOTICE severity of every Magento log.
#
# VERSION       :0.2.0
# DATE          :2017-06-13
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install logtail
# LOCATION      :/usr/local/bin/magento-report.sh

# Cron job
#
#     59 *	* * *	USER	/usr/local/bin/magento-report.sh /home/USER/website/html/var/log/
#
# Last minute tries to make sure there is a new log file at 00:59.

ZEND_LOG_LEVELS="NOTICE|WARN|ERR|CRIT|ALERT|EMERG"
declare -i EXTRA_LINES="3"

set -e

# Log directory
LOG_PATH="$1"
test -d "$LOG_PATH"

# No logs yet
compgen -G "${LOG_PATH}/*.log" > /dev/null || exit 0

# Take new lines, limit at 5 MB and look for errors
find "$LOG_PATH" -name "*.log" -exec /usr/sbin/logtail2 "{}" ";" \
    | dd bs=1M count=5 2> /dev/null \
    | grep -E -A "$EXTRA_LINES" "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+\S+ (${ZEND_LOG_LEVELS}) \([0-9]\):" \
    || if [ $? != 1 ]; then
        # This is a real error, 1 is "not found"
        exit 102
    fi

# @TODO Add var/report/*

exit 0
