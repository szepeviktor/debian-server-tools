#!/bin/bash
#
# Check PTR-A-PTR of all IP addresses in a CIDR range.
#

Error() {
    shift
    echo "ERROR: $*" 1>&2
}

Dnsquery() {
    # Dnsquery() ver 1.5.0
    # error 1:  Empty host/IP
    # error 2:  Invalid answer
    # error 3:  Invalid query type
    # error 4:  Not found

    local TYPE="$1"
    local HOST="$2"
    local RR_SORT
    local IP
    local ANSWER
    local IP_REGEX='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    local HOST_REGEX='^[a-z0-9A-Z.-]+$'

    # Empty host/IP
    [ -z "$HOST" ] && return 1

    # Sort MX records
    if [ "$TYPE" == "MX" ]; then
        RR_SORT="sort -k 6 -n -r"
    else
        RR_SORT="cat"
    fi

    # Last record only, first may be a CNAME
    IP="$(LC_ALL=C host -W 2 -t "$TYPE" "$HOST" 2> /dev/null | ${RR_SORT} | tail -n 1)"

    # Not found
    if [ -z "$IP" ] || [ "$IP" != "${IP/ not found:/}" ] || [ "$IP" != "${IP/ has no /}" ]; then
        return 4
    fi

    case "$TYPE" in
        A)
            ANSWER="${IP#* has address }"
            ANSWER="${ANSWER#* has IPv4 address }"
            if grep -qE "$IP_REGEX" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # Invalid IP
                return 2
            fi
        ;;
        PTR)
            ANSWER="${IP#* domain name pointer }"
            ANSWER="${ANSWER#* points to }"
            if grep -qE "$HOST_REGEX" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # Invalid hostname
                return 2
            fi
        ;;
        *)
            # Unknown type
            return 3
        ;;
    esac
    return 0
}

Ptr_a_ptr() {
    local A="$1"
    local PTR

    if PTR="$(Dnsquery PTR "$A")"; then
        if ! Dnsquery A "$PTR"; then
            Error 21 "No A record for ${PTR}"
        fi
    else
        Error 20 "No PTR record for ${A}"
    fi
}

Prips() {
    local CIDR="$1"
    local FIRST
    local LAST
    local A B C D E F G H

    FIRST="$(sipcalc "${CIDR}" | sed -n -e 's#^Network address\s\+- \([0-9.]\+\)$#\1#p')"
    LAST="$(sipcalc "${CIDR}" | sed -n -e 's#^Broadcast address\s\+- \([0-9.]\+\)$#\1#p')"

    IFS="." read -r A B C D <<<"${FIRST}"
    IFS="." read -r E F G H <<<"${LAST}"

    eval "echo {$A..$E}.{$B..$F}.{$C..$G}.{$D..$H}"
}

set -e

for IP in $(Prips "$1"); do
    Ptr_a_ptr "${IP}"
done
