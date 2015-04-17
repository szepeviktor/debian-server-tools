#!/bin/bash
#
# Recheck messages in Courier mail queue.
#
# VERSION       :0.2
# DATE          :2015-04-17
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install bind9-host courier-mta netcat-traditional


# store all recipient addresses in the mailq
QUEUE="./queue.txt"
# recipient addresses passing all tests
WORKS="./ok-emails.txt"
# recipient addresses failing any test
BAD="./bad-emails.txt"

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
            ANSWER="${IP#* domain name pointer }"
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

declare -a BAD_DOMAIN

# list all recipient addresses
mailq -sort -batch | head -n -1 | cut -d';' -f 7 \
    | sort | uniq > "$QUEUE"

while read EMAIL; do
    # email domain
    DOMAIN="${EMAIL#*@}"

    # already bad?
    for DOM in "${BAD_DOMAIN[@]}"; do
        if [ "$DOMAIN" == "$DOM" ]; then
            echo "Already bad: $DOMAIN"
            echo --- >&2
            echo --- >&2
            continue 2
        fi
    done

    # MX exists?
    MXL="$(dnsquery MX "$DOMAIN")"
    MXRET=$?
    if [ $MXRET != 0 ]; then
        BAD_DOMAIN+=( "$DOMAIN" )
        host -v -W 2 -t MX "$DOMAIN" >&2
        echo "NO MX for $DOMAIN ($MXL)"
        echo --- >&2
        echo --- >&2
        continue
    fi

    # A record of MX exists?
    MXLA="$(dnsquery A "$MXL")"
    if [ $? != 0 ]; then
        echo "NO A for MX ($MXLA)"
        echo --- >&2
        echo --- >&2
        continue
    fi

    # SMTP answer?
    ( sleep 2; echo "EHLO $(hostname -f)"; sleep 1; echo "QUIT" ) \
        | nc -w 5 "$MXL" 25
    if [ $? != 0 ]; then
        BAD_DOMAIN+=( "$DOMAIN" )
        echo "NO SMTP connection for $DOMAIN"
        echo --- >&2
        echo --- >&2
        continue
    fi

    # OK!
    echo "$EMAIL" >> "$WORKS"
    echo "--OK-- $DOMAIN - $MXL ($MXRET)"
    echo
done < "$QUEUE"

# listing commands to clean mailq
for DOM in "${BAD_DOMAIN[@]}"; do
    echo "# fail:  $DOM"
    echo "$DOM" >> "$BAD"
    mailq -sort -batch | head -n -1 | grep "@${DOM};$" | cut -d';' -f 2 \
        | xargs -L1 echo "sudo -u daemon -- cancelmsg "
done

echo "# examine reported errors"
echo "cd /var/lib/courier/msgq/ && echo grep -m 2 '^I0 R ' */*"

echo "# cancel ALL"
echo "mailq -sort -batch|cut -d';' -f2|head -n -1|xargs -L1 sudo -u daemon -- cancelmsg"
