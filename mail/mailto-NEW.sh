#!/bin/bash


DNS_WATCH_RC="/etc/dnswatchrc"
#source "$DNS_WATCH_RC"
DNS_WATCH=(
    tamasidr.hu:A=149.126.77.190,A=185.11.125.110

)

#A, MX stb record checker
# from all NS-es, retry with delay

dnsquery_multi() {
    # dnsquery_multi() ver 0.1
    # error 1:  Empty host/IP
    # error 2:  Invalid answer
    # error 3:  Invalid query type
    # error 4:  Not found
    # error 5:  Missing NS

    Answer_only() {
        local TYPE="$1"

        sed  '/^;; ANSWER SECTION:$/,/^$/{//!b};d' \
            | sed -n "s/^\S\+\t\+[0-9]\+\tIN\t${TYPE}\t\(.\+\)$/\1/p"
    }

    Strip_lines() {
        local LINES="$1"
        local WHAT="$2"
        # Knot-host output
        local WHATK="$3"

        while read LINE; do
            LINE="${LINE#* ${WHAT} }"
            echo "${LINE#* ${WHATK} }"
        done <<< "$LINES"
    }

    local TYPE="$1"
    local HOST="$2"
    local RR_SORT
    local NS
    local RECURSIVE
    local OUTPUT
    local RRS
    local ANSWER
    local IP_REGEX='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    local HOST_REGEX='^[a-z0-9A-Z.-]+$'

    # Empty input
    [ -z "$HOST" ] || [ -z "$TYPE" ] && return 1

    TYPE="$(echo "$TYPE" | tr '[:lower:]' '[:upper:]')"

    # Sort MX records
    if [ "$TYPE" == "MX" ]; then
        RR_SORT="sort -k 6 -g -r"
    else
        RR_SORT="cat"
    fi

    # All but NS RR-s should be looked up without recursion
    if [ "$TYPE" == "NS" ]; then
        RECURSIVE=""
        NS=""
    else
        RECURSIVE="-r"
        NS="$3"
        if [ -z "$NS" ]; then
            return 5
        fi
    fi

    # Use a TCP connection
    if [ "${TYPE:2}" == "T/" ]; then
        RECURSIVE+=" -T"
    fi

    # -4 IPv4, -W 2 Timeout, -s No next NS, -r Non-recursive
echo DBG:LC_ALL=C host -v -4 -W 2 -s ${RECURSIVE} -t "$TYPE" "$HOST" ${NS}
    OUTPUT="$(LC_ALL=C host -v -4 -W 2 -s ${RECURSIVE} -t "$TYPE" "$HOST" ${NS} 2> /dev/null)"

    if [ $? != 0 ] \
        || [ -z "$OUTPUT" ] \
        || [ "$OUTPUT" != "${OUTPUT/ ANSWER: 0/}" ]; then
        # Not found
        return 4
    fi

    RRS="$(echo "$OUTPUT" | Answer_only "$TYPE" | ${RR_SORT})"

    case "$TYPE" in
index.hu.               300     IN      MX      10 mail15.indamail.hu.
            | sed -n "s/^\S\+\t\+[0-9]\+\tIN\t${TYPE}\t\(.\+\)$/\1/p"

        A)
            ANSWER="$(Strip_lines "$RRS" "has address" "has IPv4 address")"
            if grep -qE "$IP_REGEX" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # Invalid IP
                return 2
            fi
        ;;
        MX)
            ANSWER="$(Strip_lines "$RRS" "mail is handled by *[0-9]" "mail is handled by *[0-9]")"
            if grep -qE "$HOST_REGEX" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # Invalid mail exchanger
                return 2
            fi
        ;;
        PTR)
            ANSWER="$(Strip_lines "$RRS" "domain name pointer" "points to")"
            if grep -qE "$HOST_REGEX" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # Invalid hostname
                return 2
            fi
        ;;
        TXT)
            Strip_lines "$RRS" "descriptive text" "description is"
        ;;
        NS)
            ANSWER="$(Strip_lines "$RRS" "name server" "nameserver is")"
            if grep -qE "$HOST_REGEX" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # Invalid nameserver
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

#DBG
dnsquery_multi "$@"
