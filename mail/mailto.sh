#!/bin/bash
#
# Test ESMTP communication.
#
# VERSION       :0.3.6
# DATE          :2016-01-23
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install telnet bind9-host
# DEPENDS       :apt-get install telnet knot-host
# LOCATION      :/usr/local/bin/mailto.sh

# Usage
#     mailto.sh ADDR@ESS [MX]

pwgen16() {
    local PASSWORD=""
    local CHAR
    local R
    local P

    for LENGTH in $(seq 1 16); do
        R="$RANDOM"
        case $((R % 5)) in
            1|3)
                # Capitals 65-90 40%
                CHAR="$((65 + R % 26))"
            ;;
            2|4)
                # Letters 97-122 40%
                CHAR="$((97 + R % 26))"
            ;;
            *)
                # Digits 48-57 20%
                CHAR="$((48 + R % 10))"
            ;;
        esac
        echo -n "$(printf "\x$(printf "%x" "$CHAR")")" #"
    done
}

dnsquery() {
    # dnsquery() ver 1.5
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
        MX)
            ANSWER="${IP#* mail is handled by *[0-9] }"
            if grep -qE "$HOST_REGEX" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # Invalid mail exchanger
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
        TXT)
            ANSWER="${IP#* descriptive text }"
            ANSWER="${ANSWER#* description is }"
            if grep -qE "$HOST_REGEX" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # Invalid descriptive text
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

# Email address
RCPT="$1"

[ -z "$RCPT" ] && exit 1
[ "$RCPT" == "${RCPT%@*}" ] && exit 2

MY_IP="$(ip addr show dev eth0|sed -ne '0,/^\s*inet \([0-9\.]\+\)\b.*$/{s//\1/p}')"
ME="$(dnsquery PTR "$MY_IP")"
ME="${ME%.}"
[ -z "$ME" ] && exit 3

# Mail exchanger
if [ -z "$2" ]; then
    DOMAIN="${RCPT#*@}"
    echo -n "*"; LC_ALL=C host -W 2 -t MX "$DOMAIN" | sort -k 6 -n
    MX_REC="$(dnsquery MX "$DOMAIN")"
    [ -z "$MX_REC" ] && exit 4
else
    MX_REC="$2"
fi

# From `man s_client`
#     the session will be renegotiated if the line begins with an R
#
#     if the line begins with a Q the connection will be closed down
cat <<EOF
-------------------------------------------------------------------------------
eHLO ${ME}
mAIL FROM: <postmaster@${ME}>
rCPT TO: <${RCPT}>
dATA
-------------------------------------------------------------------------------
Date: `date -R`
From: =?utf-8?b?$(echo -n "SZÉPE Viktor"|base64)?= <postmaster@${ME}>
To: ${RCPT}
Subject: mail t3st, Sorry! / proba uzenet, Elnezest!
Message-ID: <$(date "+%Y%m%d%H%M%S").$(pwgen16)@${ME}>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8;
Content-Disposition: inline
Content-Transfer-Encoding: 8bit

Mail t3st. Sorry! ${MYIP}
Proba uzenet. Elnezest! ${MYIP}
.
-------------------------------------------------------------------------------
qUIT
-------------------------------------------------------------------------------
STARTTLS:  openssl s_client -crlf -connect ${MX_REC}:25 -starttls smtp
EOF

# Only CRLF line ends
#nc -C "${MX_REC}" 25
telnet "$MX_REC" 25
