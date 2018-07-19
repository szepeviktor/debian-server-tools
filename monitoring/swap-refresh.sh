#!/bin/bash
#
# Prevent increasing swap usage by turning swap off and on.
#
# VERSION       :0.5.4
# DATE          :2018-07-19
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/swap-refresh.sh
# CRON-DAILY    :/usr/local/sbin/swap-refresh.sh

# Maximum swap to refresh, in kB
declare -i SWAP_MAX=256000

set -e

SELF="swap-refresh[$$]"

declare -i SWAP_USED
declare -i MEM_FREE
declare -i CACHES
declare -i TOTAL_FREE

# First swap only, in kB
#SWAP_USED="$(( $(/sbin/swapon --noheadings --raw --show=USED --bytes | head -n 1) / 1024 ))"
SWAP_USED="$(sed -n -e '2s/^\(\S\+\s\+\)\{3\}\([0-9]\+\)\b.*$/\2/p' /proc/swaps)"

# Less than 10 MB usage
if [ "$SWAP_USED" -lt 10240 ]; then
    logger -t "$SELF" "Little or no swap usage, no refresh"
    exit 0
fi

# Too much swap usage
if [ "$SWAP_USED" -ge "$SWAP_MAX" ]; then
    logger -t "$SELF" "Swap usage is over maximum! (${SWAP_USED} kB)"
    echo "Swap usage is over maximum! (${SWAP_USED} kB)" 1>&2
    exit 10
fi

MEM_FREE="$(/usr/bin/free -k | sed -n -e 's/^Mem:\(\s\+[0-9]\+\b\)\{2\}\s\+\([0-9]\+\)\b.*$/\2/p')"
CACHES="$(/usr/bin/free -k | sed -n -e 's/^Mem:\(\s\+[0-9]\+\b\)\{5\}\s\+\([0-9]\+\)\b.*$/\2/p')"
TOTAL_FREE="$((MEM_FREE + CACHES))"

# Swap won't fit into memory
if [ "$TOTAL_FREE" -le "$SWAP_USED" ]; then
    logger -t "$SELF" "Not enough free memory! (${TOTAL_FREE} kB)"
    echo "Not enough free memory! (${TOTAL_FREE} kB)" 1>&2
    exit 11
fi

logger -t "$SELF" "Disabling swap"
/sbin/swapoff --all || echo "swapoff ERROR $?" 1>&2

logger -t "$SELF" "Enabling swap"
/sbin/swapon --all || echo "swapon ERROR $?" 1>&2

logger -t "$SELF" "Swap refresh done"

exit 0
