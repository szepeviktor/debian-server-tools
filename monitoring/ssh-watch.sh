#!/bin/bash
#
# Check SSH connection.
#
# VERSION       :0.1.9
# DATE          :2015-11-12
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install bind9-host scanssh s-nail
# LOCATION      :/usr/local/bin/ssh-watch.sh
# CRON-HOURLY   :/usr/local/bin/ssh-watch.sh
# CONFIG        :/etc/ssh-watchrc

# Configuration syntax
#
#     SKIP_HOST="qss.qupdate.net"
#     SKIP_UNTIL="2015-07-31 10:00"
#     ALERT_ADDRESS="admin@szepe.net"
#     # bix.he.net.
#     #     http://bix.hu/index.php?lang=en&op=full&page=stat&nodefilt=1
#     ALWAYS_ONLINE="193.188.137.175"
#     INTERNET_IF="eth0"
#     RETRY_TIME="40"
#     SSH_WATCH=(
#       HOSTNAME:PORT
#       2/szepe.net:22
#     )
#
# Host names should have only DNS A records.

DAEMON="ssh-watch"
SSH_WATCH_RC="/etc/sshwatchrc"

# Defaults
SKIP_HOST=""
SKIP_UNTIL=""
ALERT_ADDRESS="admin@szepe.net"
ALWAYS_ONLINE="8.8.8.8"
INTERNET_IF="eth0"
RETRY_TIME="40"
declare -a SSH_WATCH=( )

Log() {
    local MESSAGE="$1"

    if [ -t 0 ]; then
        echo "$MESSAGE" 1>&2
    else
        logger -t "${DAEMON}[$$]" "$MESSAGE"
    fi
}

Is_online() {
    if ! ping -c 5 -W 2 -n "$ALWAYS_ONLINE" 2>&1 | grep -q ', 0% packet loss,'; then
        Log "Server is OFFLINE."
        Alert "Network connection" "pocket loss on pinging ${ALWAYS_ONLINE}"
        exit 100
    fi
}

Alert() {
    local SUBJECT="$1"

    Log "${SUBJECT} is DOWN"
    echo "$*" | s-nail -S "hostname=" -S from="${DAEMON} <root>" -s "[alert] SSH failure: ${SUBJECT}" "$ALERT_ADDRESS"
}

# shellcheck disable=SC1090
source "$SSH_WATCH_RC"

Is_online

# Check all hosts
for HOST in "${SSH_WATCH[@]}"; do
    HNAME="${HOST%%:*}"
    PORT="${HOST#*:}"
    declare -i RETRY="0"

    # May fail once by prepending "2/"
    if [ "${HNAME:0:2}" == "2/" ]; then
        HNAME="${HNAME:2}"
        HRETRY="1"
    fi

    # Skip a host
    if [ -n "$SKIP_HOST" ] && [ -n "$SKIP_UNTIL" ] \
        && [ "$HNAME" == "$SKIP_HOST" ] \
        && [ "$(date "+%s")" -lt "$(date --date="$SKIP_UNTIL" "+%s")" ]; then
        continue
    fi

    if LC_ALL=C host -W 2 -t A "$HNAME" 2>&1 | grep -q -v ' has\( IPv4\)\? address '; then
        Alert "${HNAME}/DNS" "Failed to get address of ${HNAME}"
        continue
    fi

    declare -i RETRY="$HRETRY"
    # Retry at most once
    while true; do
        scanssh -i "$INTERNET_IF" -n "$PORT" "$HNAME" 2>&1 | grep -q "^[0-9.]\\+:${PORT} SSH-2\\.0-OpenSSH_"
        SCAN_RET="$?"
        # Exit loop on successful scan or no more retries
        if [ "$SCAN_RET" == 0 ] || [ "$RETRY" -eq 0 ]; then
            break
        fi
        RETRY+="-1"
        sleep "$RETRY_TIME"
    done
    if [ "$SCAN_RET" != 0 ]; then
        Alert "${HNAME}/SSH" "Failed to scan host ${HNAME} on SSH port ${PORT}"
        continue
    fi

    Log "${HNAME} OK"

    # Pause between scans
    sleep 1
done

exit 0
