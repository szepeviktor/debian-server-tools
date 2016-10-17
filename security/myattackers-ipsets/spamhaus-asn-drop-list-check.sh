#!/bin/bash

# https://www.spamhaus.org/drop/
AS_LIST="asndrop.txt"

# List ipsets
#   Determine first IP addresses
#   Determine AS number
#   Find in AS list
cat ipset/*.ipset | sed -n -e 's|^add \S\+ \(\S\+\)$|\1|p' \
    | xargs -n1 sipcalc | sed -n -e 's|^Usable range\s*- \(\S\+\) - \(\S\+\)$|\1\n\2|p' \
    | xargs -n1 geoiplookup -f /usr/share/GeoIP/GeoIPASNum.dat | sed -n -e 's|^GeoIP ASNum Edition: \(AS[0-9]\+\) .*$|\1|p' \
    | grep -w -f - "$AS_LIST"
