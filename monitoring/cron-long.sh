#!/bin/bash
#
# Alert on long-running cron jobs.
#
# VERSION       :0.4.0
# DATE          :2017-11-14
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/cron-long.sh
# CRON.D        :*/30 *  * * *  root	/usr/local/sbin/cron-long.sh

# Age threshold in minutes
declare -i CRON_MAX_AGE="50"

declare -i CRON_CHILD_AGE

CROND_PID="$(head -n 1 /run/crond.pid)"

# Oldest cron job
CRON_CHILD_PID="$(pgrep --parent "$CROND_PID" --oldest)"

if [ -z "$CRON_CHILD_PID" ]; then
    exit 0
fi

# Check age of each cron job
ps -o etimes= -p "$CRON_CHILD_PID" \
    | while read -r CRON_CHILD_AGE; do
        if [ "$CRON_CHILD_AGE" -lt $((CRON_MAX_AGE * 60)) ]; then
            continue
        fi

        # Alert on long-running jobs
        CRON_CHILD_INFO="$(ps -o euser= --ppid "$CRON_CHILD_PID"):${CRON_CHILD_PID}:$(ps -o cmd= --ppid "$CRON_CHILD_PID")"
        echo "Cron job (${CRON_CHILD_INFO}) is running for more than ${CRON_MAX_AGE} minutes." 1>&2
    done

exit 0
