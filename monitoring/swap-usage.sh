#!/bin/bash
#
# Display swap usage by process.
#
# SOURCE         :http://unix.stackexchange.com/questions/71714/linux-total-swap-used-swap-used-by-processes
# LOCATION       :/usr/local/sbin/swap-usage.sh

for PROC in /proc/[0-9]*; do
    [ -f "${PROC}/smaps" ] && grep -q "^Swap:" "${PROC}/smaps" && cat "${PROC}/smaps" \
        | awk '/Swap/{swap+=$2}END{print swap "\t'$(readlink "${PROC}/exe" | awk '{print $1}')'" }'
done \
    | grep -v "^0\s" | sort -n \
    | awk '{total+=$1}/[0-9]/;END{print total "\tTotal"}'
