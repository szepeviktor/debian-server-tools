#!/bin/bash
#
# Test ESMTP communication.
#
# VERSION       :0.3.9
# DATE          :2018-11-28
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install telnet bind9-host
# LOCATION      :/usr/local/bin/mailto.sh

# Usage
#     mailto.sh ADDR@ESS [MX]

Pwgen16()
{
    local CHAR
    local RAND

    for _ in {1..16}; do
        RAND="$RANDOM"
        case $((RAND % 5)) in
            1|3)
                # Capitals 65-90 40%
                CHAR="$((65 + RAND % 26))"
            ;;
            2|4)
                # Letters 97-122 40%
                CHAR="$((97 + RAND % 26))"
            ;;
            *)
                # Digits 48-57 20%
                CHAR="$((48 + RAND % 10))"
            ;;
        esac
        # shellcheck disable=SC2059
        printf "\\x$(printf "%x" "$CHAR")"
    done
}

Dnsquery()
{
    # Dnsquery() ver 1.5
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

test -z "$RCPT" && exit 1
test "$RCPT" == "${RCPT%@*}" && exit 2

OWN_IP="$(ip addr show scope global up | sed -n -e '0,/^\s*inet \([0-9.]\+\)\b.*$/{s//\1/p}')"
if [ -r /etc/courier/defaultdomain ]; then
    ME="$(head -n 1 /etc/courier/defaultdomain)"
else
    ME="$(Dnsquery PTR "$OWN_IP")"
    ME="${ME%.}"
fi
test -z "$ME" && exit 3

# Mail exchanger
if [ -z "$2" ]; then
    DOMAIN="${RCPT#*@}"
    printf '*'; LC_ALL=C host -W 2 -t MX "$DOMAIN" | sort -k 6 -n
    MX_REC="$(Dnsquery MX "$DOMAIN")"
    test -z "$MX_REC" && exit 4
else
    MX_REC="$2"
fi

# From s_client(1)
#
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
Date: $(date -R)
From: =?utf-8?b?$(printf 'SZÉPE Viktor' | base64)?= <postmaster@${ME}>
To: ${RCPT}
Subject: mail t3st, Sorry! / proba uzenet, Elnezest!
Message-ID: <$(date --utc "+%Y%m%d%H%M%S").$(Pwgen16)@${ME}>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8;
Content-Disposition: inline
Content-Transfer-Encoding: 8bit

Mail t3st. Sorry! ${OWN_IP}
Proba uzenet. Elnezest! ${OWN_IP}
.
-------------------------------------------------------------------------------
qUIT
-------------------------------------------------------------------------------
STARTTLS:  openssl s_client -crlf -connect ${MX_REC%.}:25 -starttls smtp
EOF

# Only CRLF line ends
#nc -C "${MX_REC}" 25
telnet "$MX_REC" 25
