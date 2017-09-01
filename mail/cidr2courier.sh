#!/bin/bash
#
# Convert CIDR IP range notation to Courier's format.
#
# VERSION       :0.1.1
# DATE          :2017-03-28
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install sipcalc
# LOCATION      :/usr/local/bin/cidr2courier.sh

# Courier: /8, /16, /24 and single IP
# CIDR: /8 - /30
#
# Usage
#     host -t TXT spf1.mailgun.org. | grep -Eo "[0-9/.]{7,}" | xargs -n 1 cidr2courier.sh

CIDR="$1"

Is_ipv4() {
    local TOBEIP="$1"
    #             0-9, 10-99, 100-199,  200-249,    250-255
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIP" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}$ ]]
}

Is_ipv4_range() {
    local TOBEIPRANGE="$1"
    local MASKBITS="${TOBEIPRANGE##*/}"
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIPRANGE" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}/[0-9]{1,2}$ ]] \
        && [ "$MASKBITS" -ge 8 ] && [ "$MASKBITS" -le 30 ]
}

Get_cidr_range() {
    local ADDRESS="$1"

    sipcalc -i "$ADDRESS" | sed -n -e '0,/^Network range\s*- \([0-9.]\+\) - \([0-9.]\+\)$/s||\1-\2|p'
}

Get_courier_ip_list() {
    local IP="$1"
    local -i DECIMAL="$2"
    local RANGE
    local FIRST_IP
    local LAST_IP

    # /8: remove three octets
    if [ "$DECIMAL" -eq 8 ]; then
        echo "${IP%.*.*.*}"
        return
    # /16: remove two octets
    elif [ "$DECIMAL" -eq 16 ]; then
        echo "${IP%.*.*}"
        return
    # /24: remove one octet
    elif [ "$DECIMAL" -eq 24 ]; then
        echo "${IP%.*}"
        return
    fi

    RANGE="$(Get_cidr_range "${IP}/${DECIMAL}")"
    FIRST_IP="${RANGE%-*}"
    LAST_IP="${RANGE#*-}"

    # /9 - /15: loop through the second octet
    if [ "$DECIMAL" -ge 9 ] && [ "$DECIMAL" -le 15 ]; then
        LEADING_OCTETS="${FIRST_IP%.*.*.*}"
        FIRST_IP_OCTET="${FIRST_IP#*.}"
        FIRST_IP_OCTET="${FIRST_IP_OCTET%.*.*}"
        LAST_IP_OCTET="${LAST_IP#*.}"
        LAST_IP_OCTET="${LAST_IP_OCTET%.*.*}"
    # /17 - /23: loop through the third octet
    elif [ "$DECIMAL" -ge 17 ] && [ "$DECIMAL" -le 23 ]; then
        LEADING_OCTETS="${FIRST_IP%.*.*}"
        FIRST_IP_OCTET="${FIRST_IP#*.*.}"
        FIRST_IP_OCTET="${FIRST_IP_OCTET%.*}"
        LAST_IP_OCTET="${LAST_IP#*.*.}"
        LAST_IP_OCTET="${LAST_IP_OCTET%.*}"
    # /25 - /30: loop through the fourth octet
    elif [ "$DECIMAL" -ge 25 ] && [ "$DECIMAL" -le 30 ]; then
        LEADING_OCTETS="${FIRST_IP%.*}"
        FIRST_IP_OCTET="${FIRST_IP#*.*.*.}"
        LAST_IP_OCTET="${LAST_IP#*.*.*.}"
    fi

    for I in $(seq "$FIRST_IP_OCTET" "$LAST_IP_OCTET"); do
        echo "${LEADING_OCTETS}.${I}"
    done
}

set -e

# Single IP
if Is_ipv4 "$CIDR"; then
    echo "$CIDR"
    exit 0
fi

# Detect invalid range
if ! Is_ipv4_range "$CIDR"; then
    echo "ERROR: Not an IPv4 range." 1>&2
    exit 10
fi

IPV4="${CIDR%/*}"
declare -i DECIMAL="${CIDR#*/}"

Get_courier_ip_list "$IPV4" "$DECIMAL"
