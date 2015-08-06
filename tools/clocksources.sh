#!/bin/bash
#
# Display kernel clock sources and mark current one.
#
# VERSION       :1.0.0
# DATE          :2015-08-06
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/clocksources.sh

CURRENT_CS="$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"

echo -n "Clock sources:"

for CS in $(cat /sys/devices/system/clocksource/clocksource0/available_clocksource); do
    if [ "$CS" == "$CURRENT_CS" ]; then
        FLAG="*"
    else
        FLAG=""
    fi
    echo -n " ${FLAG}${CS}"
done

echo
