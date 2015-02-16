#!/bin/bash
#
# Recheck the messages in Courier mail queue.
#
# VERSION       :0.1
# DATE          :2015-01-10
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
    # dnsquery() ver 1.3
    # error 1:  empty host
    # error 2:  invalid answer
    # error 3:  invalid query type
    # error 4:  not found

    local TYPE="$1"
    local HOST="$2"
    local ANSWER
    local IP

    # empty host
    [ -z "$HOST" ] && return 1

    # sort MX records
    if [ "$TYPE" == "MX" ]; then
        RR_SORT="sort -k 6 -n -r"
    else
        RR_SORT="cat"
    fi
    # last record only, first may be a CNAME
    IP="$(LC_ALL=C host -W 2 -t "$TYPE" "$HOST" 2> /dev/null | ${RR_SORT} | tail -n 1)"

    # not found
    if [ -z "$IP" ] || ! [ "$IP" = "${IP/ not found:/}" ] || ! [ "$IP" = "${IP/ has no /}" ]; then
        return 4
    fi

    case "$TYPE" in
        A)
            ANSWER="${IP#* has address }"
            if grep -q "^\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}\$" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # invalid IP
                return 2
            fi
        ;;
        MX)
            ANSWER="${IP#* mail is handled by *[0-9] }"
            if grep -q "^[a-z0-9A-Z.-]\+\$" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # invalid hostname
                return 2
            fi
        ;;
        PTR)
            ANSWER="${IP#* domain name pointer }"
            if grep -q "^[a-z0-9A-Z.-]\+\$" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # invalid hostname
                return 2
            fi
        ;;
        TXT)
            ANSWER="${IP#* domain name pointer }"
            if grep -q "^[a-z0-9A-Z.-]\+\$" <<< "$ANSWER"; then
                echo "$ANSWER"
            else
                # invalid hostname
                return 2
            fi
        ;;
        *)
            # unknown type
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
