#!/bin/bash
#
# Show human readable time in kernel messages.
#

# Detect pipe
if [ -t 0 ]; then
    echo "Usage: dmesg|dmesg.sh" >&2
    exit 1
fi

NOW="$(date "+%s")"
UPTIME="$(cut -d'.' -f 1 /proc/uptime)"
declare -i BOOT="$(( NOW - UPTIME ))"

# Cannot determine boot time
[ -z "$BOOT" ] && exit 2

while read -r KLINE; do
    # Split time and message
    # [3348067.465252] kernel: Message
    MESSAGE="$(sed 's/^\[\s*\([[:digit:]]\+\)\.[[:digit:]]\+\] \(.*\)$/\1<->\2/' <<< "$KLINE")"
    MSG_TIME="${MESSAGE%%	*}"
    MSG_TEXT="${MESSAGE#*	}"

    if [ -z "$MSG_TIME" ]; then
        # Message timestamp not found
        echo "??????????????? ${KLINE}"
    elif [ -z "${MSG_TIME//[0-9]/}" ]; then
        # Boot time + dmesg timestamp in rsyslog style
        # Nov 17 08:21:33
        TIME_STRING="$(date -d "@$(( BOOT + MSG_TIME ))" "+%b %d %H:%M:%S")" #"
        echo "${TIME_STRING} ${MSG_TEXT}"
    else
        # Message timestamp is not a number
        echo "??????????????? ${KLINE}"
    fi
done
