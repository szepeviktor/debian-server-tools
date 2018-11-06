#!/bin/bash
#
# Retrieve PTR records for an IP range list.
#
# VERSION       :0.1.0
# DATE          :2018-11-06
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install sipcalc dnsutils
# LOCATION      :/usr/local/bin/cnet

# Get prefix list file from https://bgp.he.net/AS1#_prefixes
#
# Domain top list
#$ grep -vF 'PTR record' output.ptr|sed -ne 's/.*\.\([0-9a-z.-]\+\.[a-z]\+\)\.$/\1/p'|sort|uniq -c|sort -n

PREFIX_LIST="$1"
NS="$2"

Ip2dec()
{
    local IPV4="$1"
    local -i OCTET1 OCTET2 OCTET3 OCTET4

    IFS="." read -r OCTET1 OCTET2 OCTET3 OCTET4 <<<"$IPV4"
    echo "$(( (OCTET1 << 24) + (OCTET2 << 16) + (OCTET3 << 8) + OCTET4 ))"
}

Dec2ip()
{
    local -i DEC="$1"
    local -i MAX="$(( ~(-1<<8) ))"

    echo "$(( DEC >> 24 & MAX )).$(( DEC >> 16 & MAX )).$(( DEC >> 8 & MAX )).$(( DEC & MAX ))"
}

test -r "$PREFIX_LIST"
test -n "$NS"

# Parse prefix list file
while read -r PREFIX; do
    test -z "$PREFIX" && continue
    test "${PREFIX:0:3}" == ROA && continue
    test "${PREFIX:0:3}" == IRR && continue

    FROM_TO="$(sipcalc "$PREFIX" | sed -n -e 's|^Network range\s\+- \([0-9.]\+\) - \([0-9.]\+\)$|\1:\2|p')"
    FROM="$(Ip2dec "${FROM_TO%:*}")"
    TO="$(Ip2dec "${FROM_TO#*:}")"

    # Loop through all IP addresses
    for DEC in $(seq "$FROM" "$TO"); do
        CURRENT_IP="$(Dec2ip "$DEC")"
        ANSWER="$(dig +noall +answer "@${NS}" -x "$CURRENT_IP")"
        echo "${ANSWER:-PTR record is not available for ${CURRENT_IP}}"
    done
done <"$PREFIX_LIST"
