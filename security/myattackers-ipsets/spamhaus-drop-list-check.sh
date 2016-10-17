#!/bin/bash

Spamhaus_drop_check() {
    # List ipsets
    #   Determine first and last IP addresses
    #   Find in CIDR list
    cat ipset/*.ipset | sed -n -e 's|^add \S\+ \(\S\+\)$|\1|p' \
        | xargs -n1 sipcalc | sed -n -e 's|^Usable range\s*- \(\S\+\) - \(\S\+\)$|\1\n\2|p' \
        | grepcidr -f "$CIDR_LIST"
}

# https://www.spamhaus.org/drop/
CIDR_LIST="drop.txt"
Spamhaus_drop_check

CIDR_LIST="edrop.txt"
Spamhaus_drop_check
