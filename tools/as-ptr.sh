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
# LOCATION      :/usr/local/bin/as-ptr.sh

# Get prefix list file from https://bgp.he.net/AS1#_prefixes
#
# Domain top list
#$ grep -vF 'PTR record' output.ptr|sed -ne 's/.*\.\([0-9a-z.-]\+\.[a-z]\+\)\.$/\1/p'|sort|uniq -c|sort -n

PREFIX_LIST="$1"

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

Get_ns()
{
    local IPV4="$1"
    local RESOLVER="1.1.1.1"
    local NS1

    # shellcheck disable=SC2016
    NS1="$(dig +trace "@${RESOLVER}" -x "$IPV4" | sed -n -e '/^.*\s\+IN\s\+NS\s\+\(\S\+\)$/h; ${x;s//\1/p}')"
    # Make sure it has an IP
    if [ -n "$(dig "$NS1" A +short)" ]; then
        echo "$NS1"
    fi
}

test -r "$PREFIX_LIST" || exit 10

# Parse prefix list file
while read -r PREFIX; do
    test -z "$PREFIX" && continue
    test "${PREFIX:0:3}" == ROA && continue
    test "${PREFIX:0:3}" == IRR && continue

    FROM_TO="$(sipcalc "$PREFIX" | sed -n -e 's|^Network range\s\+- \([0-9.]\+\) - \([0-9.]\+\)$|\1:\2|p')"
    FROM="$(Ip2dec "${FROM_TO%:*}")"
    TO="$(Ip2dec "${FROM_TO#*:}")"

    FIRST_IP="$(Dec2ip "$FROM")"
    NS="$(Get_ns "$FIRST_IP")"
    # Loop through all IP addresses
    #for DEC in $(seq "$FROM" "$TO"); do
    for (( DEC=FROM; DEC < TO; DEC+=1 )) do
        CURRENT_IP="$(Dec2ip "$DEC")"
        # Update resolver per /24
        if [ "${CURRENT_IP##*.}" == 0 ]; then
            NS="$(Get_ns "$CURRENT_IP")"
        fi
        printf '%s:  ' "$NS" 1>&2
        ANSWER="$(dig +noall +answer "@${NS:-1.1.1.1}" -x "$CURRENT_IP")"
        echo "${ANSWER:-PTR record is not available for ${CURRENT_IP}}"
    done
done <"$PREFIX_LIST"
