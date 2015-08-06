#!/bin/bash
#
# Check foreign DNS resource records.
#
# VERSION       :0.2.3
# DATE          :2015-08-03
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install bind9-host
# LOCATION      :/usr/local/bin/dns-watch.sh
# CRON-HOURLY   :/usr/local/bin/dns-watch.sh
# CONFIG        :/etc/dnswatchrc

# Usage
#
# Generate configuration
#
#     dns-watch.sh -d szepe.net
#
# Display RR-s
#
#     dns-watch.sh www.szepe.net
#
# Configuration syntax - ":" and "="
#
#     DNS_WATCH=(
#       domain.net:TYPE=value
#       szepe.net:A=95.140.33.67
#     )
#
# Multiple RR-s - ","
# Double-quotes and spaces must be escaped or single-quoted
#
#     szepe.net:A=95.140.33.67,TXT=\"value\ here\"
#     'szepe.net:A=95.140.33.67,TXT="value here"'
#
# Multiple values - ";" escaped
# WARNING! Values must be in `sort`-ed order.
#
#     szepe.net:NS=mark.ns.cloudflare.com.\;sue.ns.cloudflare.com.

ALERT_ADDRESS="admin@szepe.net"
# bix.he.net.
#     http://bix.hu/index.php?lang=en&op=full&page=stat&nodefilt=1
ALWAYS_ONLINE="193.188.137.175"
RETRY_TIME="40"

DAEMON="dns-watch"
DNS_WATCH_RC="/etc/dnswatchrc"
DNS_WATCH=( )
source "$DNS_WATCH_RC"

# Return all RR-s
Dnsquery_multi() {
    # dnsquery_multi() ver 0.1.0
    # error 1:  Empty host/IP
    # error 2:  Invalid answer
    # error 3:  Invalid query type
    # error 4:  Not found
    # error 5:  Missing NS

    Answer_only() {
        local TYPE="$1"

        sed  '/^;; ANSWER SECTION:$/,/^$/{//!b};d' \
            | sed -n "/^\S\+\s\+[0-9]\+\sIN\s${TYPE}\s\(.\+\)$/!q;s//\1/p"
    }

    local TYPE="$1"
    local HOST="$2"
    local NS=""
    local RR_SORT
    local RECURSIVE
    local OUTPUT
    local RRS
    local ANSWERS
    local IP_REGEX='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    local IPV6_REGEX='^[0-9a-fA-F:]+$'
    local HOST_REGEX='^[a-z0-9A-Z.-]+$'
    local MX_REGEX='^[0-9]+ [a-z0-9A-Z.-]+$'

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
        if [ -n "$3" ]; then
            NS="$3"
        fi
    else
        RECURSIVE="-r"
        NS="$3"
        if [ -z "$NS" ]; then
            return 5
        fi
    fi

    # Use a TCP connection
    if [ "${TYPE:0:2}" == "T/" ]; then
        TYPE="${TYPE:2}"
        RECURSIVE+=" -T"
    fi

    # -4 IPv4, -W 2 Timeout, -s No next NS, -r Non-recursive
    #DBG "LC_ALL=C host -v -4 -W 2 -s ${RECURSIVE} -t "$TYPE" "$HOST" ${NS} 2> /dev/null"
    OUTPUT="$(LC_ALL=C host -v -4 -W 2 -s ${RECURSIVE} -t "$TYPE" "$HOST" ${NS} 2> /dev/null)"

    if [ $? != 0 ] \
        || [ -z "$OUTPUT" ] \
        || [ "$OUTPUT" != "${OUTPUT/ ANSWER: 0/}" ]; then
        # Not found
        return 4
    fi

    ANSWERS="$(echo "$OUTPUT" | Answer_only "$TYPE" | ${RR_SORT})"

    if [ -z "$ANSWERS" ]; then
        # Not found but non-zero answers
        return 4
    fi

    case "$TYPE" in
        A)
            if grep -qEv "$IP_REGEX" <<< "$ANSWERS"; then
                # Invalid IP (at least one)
                return 2
            fi
            echo "$ANSWERS"
        ;;
        AAAA)
            if grep -qEv "$IPV6_REGEX" <<< "$ANSWERS"; then
                # Invalid IPv6 (at least one)
                return 2
            fi
            echo "$ANSWERS"
        ;;
        MX)
            if grep -qEv "$MX_REGEX" <<< "$ANSWERS"; then
                # Invalid mail exchanger (at least one)
                return 2
            fi
            echo "$ANSWERS"
        ;;
        PTR|CNAME|NS)
            if grep -qEv "$HOST_REGEX" <<< "$ANSWERS"; then
                # Invalid hostname (at least one)
                return 2
            fi
            echo "$ANSWERS"
        ;;
        TXT)
            echo "$ANSWERS"
        ;;
        *)
            # Unknown type
            return 3
        ;;
    esac
    return 0
}

#Dnsquery_multi "$@"; echo "$?" >&2; exit
#DBG() { echo "> |${*}|" >&2; }

Log() {
    local MESSAGE="$1"

    if tty --quiet; then
        echo "$MESSAGE" >&2
    else
        logger -t "${DAEMON}[$$]" "$MESSAGE"
    fi
}

Is_online() {
    if ! ping -c 5 -W 2 -n "$ALWAYS_ONLINE" 2>&1 | grep -q ", 0% packet loss,"; then
        Log "Server is OFFLINE."
        Alert "Not online" "pocket loss on pinging ${ALWAYS_ONLINE}"
        exit 100
    fi
}

Alert() {
    #DBG "E: $*"; return
    local SUBJECT="$1"

    Log "${SUBJECT} is DOWN"
    echo "$*" | mailx -s "[${DAEMON}] DNS failure: ${SUBJECT}" "$ALERT_ADDRESS"
}

Generate_rr() {
    local TYPE="$1"
    local DNAME="$2"
    local NS="$3"
    local RR

    RR="$(Dnsquery_multi "$TYPE" "$DNAME" "$NS" | sort | paste -s -d";")"
    [ $? == 0 ] && [ -n "$RR" ] && echo "${TYPE}=${RR}"
}

Is_online

# Display answers
if [ $# == 1 ]; then
    DNAME="$1"

    FIRST_NS="$(Dnsquery_multi NS "$DNAME" | head -n 1)"
    if [ $? != 0 ] || [ -z "$FIRST_NS" ]; then
        MAIN_DOMAIN="$(sed 's/^.*\.\([^.]\+\.[^.]\+\)$/\1/' <<< "$DNAME")"
        FIRST_NS="$(Dnsquery_multi NS "$MAIN_DOMAIN" | head -n 1)"
    fi

    echo "${DNAME}:"
    Generate_rr NS "$DNAME" "$FIRST_NS"
    Generate_rr A "$DNAME" "$FIRST_NS"
    Generate_rr AAAA "$DNAME" "$FIRST_NS"
    Generate_rr MX "$DNAME" "$FIRST_NS"
    Generate_rr CNAME "$DNAME" "$FIRST_NS"
    Generate_rr TXT "$DNAME" "$FIRST_NS"

    exit 0
fi

# Generate configuration for a domain
if [ "$1" == "-d" ] && [ $# == 2 ]; then
    DNAME="$2"

    FIRST_NS="$(Dnsquery_multi NS "$DNAME" | head -n 1)"
    if [ $? != 0 ] || [ -z "$FIRST_NS" ]; then
        MAIN_DOMAIN="$(sed 's/^.*\.\([^.]\+\.[^.]\+\)$/\1/' <<< "$DNAME")"
        FIRST_NS="$(Dnsquery_multi NS "$MAIN_DOMAIN" | head -n 1)"
    fi

    DOMAIN_CONFIG="$(
        Generate_rr NS "$DNAME" "$FIRST_NS"
        Generate_rr A "$DNAME" "$FIRST_NS"
        Generate_rr AAAA "$DNAME" "$FIRST_NS"
        Generate_rr MX "$DNAME" "$FIRST_NS"
        Generate_rr CNAME "$DNAME" "$FIRST_NS"
        Generate_rr TXT "$DNAME" "$FIRST_NS"
    )"

    if [ -z "$DOMAIN_CONFIG" ]; then
        echo "No RR-s found for ${DNAME}" >&2
        exit 2
    fi

    # Escape spaces, double-quotes and semi-colons
    DOMAIN_CONFIG="${DOMAIN_CONFIG// /\\ }"
    DOMAIN_CONFIG="${DOMAIN_CONFIG//\"/\\\"}"
    DOMAIN_CONFIG="${DOMAIN_CONFIG//;/\\;}"

    echo -e "DNS_WATCH+=(\n  ${DNAME}:$(paste -s -d"," <<< "${DOMAIN_CONFIG}")\n)" >> "$DNS_WATCH_RC"

    # Make me remember www domain
    if [ "$DNAME" == "${DNAME#www}" ]; then
        echo "$0 -d www.${DNAME}" >&2
    fi

    exit 0
fi

# Check all domains
for DOMAIN in "${DNS_WATCH[@]}"; do
    DNAME="${DOMAIN%%:*}"
    RRS="${DOMAIN#*:}"
    declare -i DRETRY="0"
    declare -i RETRY="0"

    # May fail once
    if [ "${DNAME:0:2}" == "2/" ]; then
        DNAME="${DNAME:2}"
        DRETRY="1"
    fi

    NSS="$(Dnsquery_multi NS "$DNAME")"
    if [ $? != 0 ] || [ -z "$NSS" ]; then
        MAIN_DOMAIN="$(sed 's/^.*\.\([^.]\+\.[^.]\+\)$/\1/' <<< "$DNAME")"
        NSS="$(Dnsquery_multi NS "$MAIN_DOMAIN")"
    fi
    if [ $? != 0 ] || [ -z "$NSS" ]; then
        Alert "${DNAME}/NS" \
            "Failed to get NS RR-s of ${DNAME}"
        continue
    fi

    # Check RR-s
    while read -d"," RR; do
        #DBG "$RR"
        if [ -z "$RR" ]; then
            echo "Empty RR in config for ${DNAME}" >&2
            exit 101
        fi
        RRTYPE="${RR%%=*}"
        RRVALUES="${RR#*=}"
        RRVALUES_SORTED="$(sort <<< "$RRVALUES")"

        # All nameservers
        while read NS; do

            # Actual IP address of nameserver
            NS_IP="$(getent ahostsv4 "$NS" | sed -n '0,/^\(\S\+\)\s\+RAW\b/s//\1/p')"
            # UDP and TCP lookup
            for PROTO in "" "T/"; do

                # Retry at most once
                RETRY="$DRETRY"
                while true; do
                    ANSWERS="$(Dnsquery_multi "${PROTO}${RRTYPE}" "$DNAME" "$NS_IP")"
                    QUERY_RET="$?"
                    #DBG "${DNAME}/${RRTYPE}/${NS}=${NS_IP}/${PROTO}: $ANSWERS"

                    # Exit the loop on successful query or no more retries
                    if [ "$QUERY_RET" == 0 ] || [ "$RETRY" == 0 ]; then
                        break
                    fi
                    RETRY+="-1"
                    sleep "$RETRY_TIME"
                done
                if [ "$QUERY_RET" != 0 ]; then
                    Alert "${DNAME}/${RRTYPE}/${NS}/${PROTO}" \
                        "Failed to query type ${RRTYPE} of ${DNAME} from ${NS}=${NS_IP} on protocol (${PROTO:0:1})"
                    continue
                fi
                ANSWERS_SORTED="$(sort <<< "$ANSWERS" | paste -s -d";")"
                if [ "$ANSWERS_SORTED" != "$RRVALUES_SORTED" ]; then
                    #DBG "$ANSWERS_SORTED||$RRVALUES_SORTED"
                    Alert "${DNAME}/${RRTYPE}/${NS}/${PROTO}" \
                        "CHANGED answer to query type ${RRTYPE} of ${DNAME} from ${NS}=${NS_IP} on protocol (${PROTO:0:1})"
                    continue
                fi
            done
        done <<< "$NSS"
    done <<< "${RRS},"

    Log "${DNAME} OK"
    # Pause DNS queries
    sleep 1
done

exit 0
