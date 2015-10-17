#!/bin/bash
#
# Prevent increasing swap usage by turning swap off and on.
#
# VERSION       :0.4.0
# DATE          :2015-10-11
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/swap-refresh.sh
# CRON-DAILY    :/usr/local/sbin/swap-refresh.sh

# Maximum swap to refresh, in kB
SWAP_MAX=256000

SELF="swap-refresh[$$]"

# First swap only, in kB
#     SWAP_USED="$(( $(/sbin/swapon --noheadings --show=USED --bytes | head -n 1) / 1024 ))"
SWAP_USED="$(sed -n '2s/^\(\S\+\s\+\)\{3\}\([0-9]\+\)\b.*$/\2/p' /proc/swaps)"
MEM_FREE="$(/usr/bin/free -k | sed -n 's/^Mem:\(\s\+[0-9]\+\b\)\{2\}\s\+\([0-9]\+\)\b.*$/\2/p')"

if [ "$SWAP_USED" -ge "$SWAP_MAX" ]; then
    echo "Swap usage is over maximum! (${SWAP_USED} kB)" >&2
    exit 1
fi
if [ "$MEM_FREE" -le "$SWAP_USED" ]; then
    echo "Not enough free memory! (${MEM_FREE} kB)" >&2
    exit 2
fi

logger -t "$SELF" "Swap OFF"
/sbin/swapoff -a || echo "swapoff ERROR $?" >&2

logger -t "$SELF" "Reactivating swap"
/sbin/swapon -a || echo "swapon ERROR $?" >&2

logger -t "$SELF" "Swap refresh done"
