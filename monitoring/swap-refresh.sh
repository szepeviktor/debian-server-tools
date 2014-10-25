#!/bin/bash
#
# Prevent increasing swap usage by turning swap off and on.
#
# VERSION       :0.2
# DATE          :2014-10-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/swap-refresh.sh
# CRON-DAILY    :/usr/local/sbin/swap-refresh.sh


# maximum swap to refresh, in kB
SWAP_MAX=256000
###############

# first swap only, in kB (collapse whitespaces)
SWAP_USAGE="$(tail -n +2 /proc/swaps | head -n 1 | sed 's/\s\+/ /g' | cut -d' ' -f 4)"
FREE_MEM="$(free -k | grep '^Mem' | sed 's/\s\+/ /g' | cut -d' ' -f 3)"

if [ "$SWAP_USAGE" -ge "$SWAP_MAX" ]; then
    echo "Swap usage is over maximum! (${SWAP_USAGE} kB)" >&2
    exit 1
fi
if [ "$FREE_MEM" -le "$SWAP_USAGE" ]; then
    echo "Not enough free memory! (${FREE_MEM} kB)" >&2
    exit 2
fi

logger -t "swap-refresh" "Swap OFF"
/sbin/swapoff -a || echo "swapoff: ERROR $?" >&2

logger -t "swap-refresh" "reactivating swap"
/sbin/swapon -a || echo "swapon: ERROR $?" >&2

logger -t "swap-refresh" "Swap refresh done."
