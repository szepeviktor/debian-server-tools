#!/bin/bash
#
# Show human readable time in kernel messages.
#
# VERSION       :1.0.1
# DATE          :2015-06-06
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/dmesg.sh

# Depreceted, use: dmesg -T

# Detect pipe
if [ -t 0 ]; then
    echo "Usage: dmesg|dmesg.sh" 1>&2
    exit 1
fi

NOW="$(date "+%s")"
UPTIME="$(cut -d "." -f 1 /proc/uptime)"
declare -i BOOT="$(( NOW - UPTIME ))"

# Cannot determine boot time
[ -z "$BOOT" ] && exit 2

while read -r KLINE; do
    # Split time and message
    # For example: [3348067.465252] kernel: Message
    MESSAGE="$(sed 's/^\[\s*\([[:digit:]]\+\)\.[[:digit:]]\+\] \(.*\)$/\1	\2/' <<< "$KLINE")"
    MSG_TIME="${MESSAGE%%	*}"
    MSG_TEXT="${MESSAGE#*	}"

    if [ -z "$MSG_TIME" ] || [ -n "${MSG_TIME//[0-9]/}" ]; then
        # Message timestamp not found or not a number
        echo "??????????????? ${KLINE}"
    else
        # Replace timestamp with: Dec 31 23:59:59
        TIME_STRING="$(date -d "@$(( BOOT + MSG_TIME ))" "+%b %d %H:%M:%S")"
        echo "${TIME_STRING} ${MSG_TEXT}"
    fi
done
