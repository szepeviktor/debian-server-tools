#!/bin/bash
#
# Install cron jobs from the script header.
# E.g. "# CRON-HOURLY    :/usr/local/bin/example.sh"
#
# VERSION       :0.1
# DATE          :2014-11-04
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+


Die() {
    local RET="$1"
    shift
    echo -e $@ >&2
    exit "$RET"
}

Valid_cron_interval() {
    local QUESTION="$1"

    for VALID in cron.daily cron.hourly cron.monthly cron.weekly; do
        if [ "$QUESTION" == "$VALID" ]; then
            return 0
            return
        fi
    done

    return 1
}

#########################################################

[ "$(id --user)" = 0 ] || Die 1 "Only root is allowed to install cron jobs."

[ -f "$1" ] || Die 2 "Please specify a script."

SCRIPT="$1"

CRON_JOBS="$(head -n 40 "$SCRIPT" | grep -i "^# CRON-")"

[ -z "$CRON_JOBS" ] && Die 3 "No cron job in script."

while read -r JOB; do
    INTERVAL="$(echo "$JOB" | cut -d' ' -f 2)"
    INTERVAL="$(tr '[:upper:]' '[:lower:]' <<< "$INTERVAL")"
    INTERVAL="${INTERVAL/-/.}"

    if Valid_cron_interval "$INTERVAL"; then
        CRON_FILE="/etc/${INTERVAL}/$(basename "$SCRIPT")"
        echo -e ":#!/bin/bash\n${JOB}" | cut -d':' -f 2 > "$CRON_FILE"
        chmod 755 "$CRON_FILE"
        echo "${SCRIPT} -> ${CRON_FILE}"
    else
        Die "Invalid cron interval in script header: (${INTERVAL})"
    fi
done <<< "$CRON_JOBS"
