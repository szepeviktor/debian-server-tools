#!/bin/bash
#
# Uninstall cron jobs from the script header.
#
# VERSION       :0.1.0
# DATE          :2015-
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+

Die() {
    local RET="$1"

    shift

    echo -e "$*" 1>&2
    exit "$RET"
}

Valid_cron_interval() {
    local QUESTION="$1"

    for VALID in cron.daily cron.hourly cron.monthly cron.weekly; do
        if [ "$QUESTION" == "$VALID" ]; then
            return 0
        fi
    done

    return 1
}

SCRIPT="$1"

if [ "$(id --user)" -ne 0 ]; then
    Die 1 "Only root is allowed to install cron jobs."
fi

if [ ! -f "$SCRIPT" ]; then
    Die 2 "Please specify an existing script."
fi

#TODO rewrite: loop through valid crons and `head -n 30 "$SCRIPT"|grep -i "^# ${CRON}")"|cut -d':' -f2 >> "$CRON_FILE"`
CRON_JOBS="$(head -n 30 "$SCRIPT" | grep -i "^# CRON")"

test -z "$CRON_JOBS" && Die 3 "No cron job in script."

declare -i JOB_ID="0"

while read -r JOB; do
    CRON_INTERVAL="$(echo "$JOB" | cut -d ' ' -f 2 | tr '[:upper:]' '[:lower:]')"
    CRON_INTERVAL="${CRON_INTERVAL/-/.}"

    if Valid_cron_interval "$CRON_INTERVAL"; then
        CRON_FILE="/etc/${CRON_INTERVAL}/$(basename "${SCRIPT%.*}")$(( ++JOB_ID ))"
        rm -v "$CRON_FILE"
    elif [ "$CRON_INTERVAL" == cron.d ]; then
        CRON_FILE="/etc/cron.d/$(basename "${SCRIPT%.*}")"
        rm -v "$CRON_FILE"
    else
        Die "Invalid cron interval in script header: (${CRON_INTERVAL})"
    fi
done <<< "$CRON_JOBS"
