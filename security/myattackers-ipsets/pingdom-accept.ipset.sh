#!/bin/bash
#
# Whitelist Pingdom probe servers.
#

ipset create pingdom hash:net family inet hashsize 64 maxelem 256
ipset flush pingdom

wget -q -O- "https://my.pingdom.com/probes/ipv4" \
    | xargs -t -L1 -- ipset add pingdom

iptables -w -I INPUT -m set --match-set pingdom src -j ACCEPT
