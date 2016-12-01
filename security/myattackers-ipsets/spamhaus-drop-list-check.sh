#!/bin/bash

Spamhaus_drop_check() {
    local CIDR_LIST="$1"

    # List ipsets
    #   Determine first and last IP addresses
    #   Find in CIDR list
    cat ipset/*.ipset | sed -n -e 's|^add \S\+ \(\S\+\)$|\1|p' \
        | xargs -n1 sipcalc | sed -n -e 's|^Usable range\s*- \(\S\+\) - \(\S\+\)$|\1\n\2|p' \
        | grepcidr -f "$CIDR_LIST"
}

# https://www.spamhaus.org/drop/
wget -nv -N https://www.spamhaus.org/drop/drop.txt
wget -nv -N https://www.spamhaus.org/drop/edrop.txt
Spamhaus_drop_check "drop.txt"
Spamhaus_drop_check "edrop.txt"
