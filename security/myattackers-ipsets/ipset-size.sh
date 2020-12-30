#!/bin/bash

find ipset/ -type f -name "*.ipset" \
    | sort \
    | while read -r IPSET; do
        printf '%24s: %8d\n' "$(basename "$IPSET" .ipset)" \
            "$(grep '^add' "$IPSET"|cut -d" " -f3|xargs -L1 sipcalc|grep 'Addresses in network'|cut -d" " -f4|paste -s -d+|bc)"
    done

# Display difference to installed IP sets
# colordiff <(/sbin/ipset save|grep '^add'|sort) <(cat ipset/*.ipset|grep '^add'|sort)
