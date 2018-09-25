#!/bin/bash

find ipset/ -type f -name "*.ipset" \
    | while read -r IPSET; do
        printf '%24s: %8d\n' "$(basename "$IPSET" .ipset)" \
            "$(grep '^add' "$IPSET"|cut -d" " -f3|xargs -L1 sipcalc|grep 'Addresses in network'|cut -d" " -f4|paste -s -d+|bc)"
    done
