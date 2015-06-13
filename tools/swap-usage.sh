#!/bin/bash
#
# Display swap usage by process in kilobytes.
#
# VERSION       :0.2
# DATE          :2015-06-13
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# SOURCE        :http://unix.stackexchange.com/questions/71714/linux-total-swap-used-swap-used-by-processes
# LOCATION      :/usr/local/sbin/swap-usage.sh

for PROC in /proc/[0-9]*; do
    [ -f "${PROC}/smaps" ] && grep -q "^Swap:" "${PROC}/smaps" \
        && cat "${PROC}/smaps" \
        | awk '/Swap/{swap+=$2}END{print swap "\t'"$(readlink "${PROC}/exe" | awk '{print $1}')"'" }'
done \
    | grep -v "^0\s" | sort -n \
    | awk '{total+=$1}/[0-9]/;END{print total "\tTotal"}'
