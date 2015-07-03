#!/bin/bash

CURRENT_CS="$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"

echo -n "clocksources:"
while read -d' ' CS; do
    FLAG=""
    [ "$CS" = "$CURRENT_CS" ] && FLAG="*"
    echo -n " ${FLAG}${CS}"
done < /sys/devices/system/clocksource/clocksource0/available_clocksource
echo
