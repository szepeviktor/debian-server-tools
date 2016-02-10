#!/bin/bash
#
# Alert on long-running cron jobs.
#
# VERSION       :0.1.0
# DATE          :2016-02-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/cron-old.sh
# CRON.D        :* *	* * *	root	/usr/local/sbin/cron-old.sh

declare -i CRON_MAX_AGE="10"
declare -i CRON_CHILD_AGE

# Oldest cron job
CRON_CHILD_PID="$(pgrep --parent $(cat /run/crond.pid) --oldest)"

[ -z "$CRON_CHILD_PID" ] && exit 0

# List job ages
ps -o etimes= -p "$CRON_CHILD_PID" \
    | while read -r CRON_CHILD_AGE; do
        [ "$CRON_CHILD_AGE" -lt $((CRON_MAX_AGE * 60)) ] && continue

        CRON_CHILD_INFO="${CRON_CHILD_PID}:$(ps -o cmd= --ppid "$CRON_CHILD_PID")"
        echo "Cron job (${CRON_CHILD_INFO}) is running for more than ${CRON_MAX_AGE} minutes." 1>&2
    done

exit 0
