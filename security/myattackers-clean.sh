#!/bin/bash
#
# Remove old MYATTACKERS rules without traffic.
#
# VERSION       :0.2.0
# DATE          :2015-08-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/myattackers-clean.sh
# CRON-WEEKLY   :/usr/local/sbin/myattackers-clean.sh

MYATTACKERS_CHAIN="MYATTACKERS"

# List rules,
#   only old rules (20+ line number) without traffic,
#   in reverse order,
#   delete rules
iptables --line-numbers -n -v -L "$MYATTACKERS_CHAIN" \
    | sed -n '22,$s/^\([0-9]\+\)\s\+0\s\+0\s\+DROP\s.*$/\1/p' \
    | sort -r -n \
    | xargs -r -L 1 iptables -D "$MYATTACKERS_CHAIN"

# Zero the packet and byte counters
iptables -Z "$MYATTACKERS_CHAIN"
