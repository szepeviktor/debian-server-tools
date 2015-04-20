#!/bin/bash
#
# Clean up an email list.
#
# VERSION       :0.2
# DATE          :2015-04-16
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/mx-check.sh
# DEPENDS       :apt-get install bind9-host netcat-traditional courier-mta

# Assumed MTA user
MAIL_GROUP="daemon"

ORIG_LIST="$1"
EMAIL_REGEXP='\b[a-zA-Z0-9._-]\+@[a-zA-Z][a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,6\}\b'
CLEAN_LIST="${ORIG_LIST}.0-clean.txt"
LINES_FAILED="${ORIG_LIST}.0-FAILED-lines.txt"
DOMAIN_LIST="${ORIG_LIST}.1-domains.txt"
SMTP_OK_LIST="${ORIG_LIST}.2-smtp-ok.txt"
SMTP_FAIL_LIST="${ORIG_LIST}.2-FAILED-smtp.txt"

Die() {
    local RET="$1"
    shift
    echo -e $@ >&2
    exit "$RET"
}

Progress() {
    echo -n "." >&2
}

# Clean up list
Email_cleanup() {
    local LIST="$1"

    # search, trim
    cat "$LIST" | grep -o "$EMAIL_REGEXP"

    # failed lines
    grep -v "$EMAIL_REGEXP" "$LIST" | grep -v "^\s*$" >&2
}

# Converts an address-per-line files to unique domain list.
Addr2dom() {
    local LIST="$1"

    # lowercase domain names
    cat "$LIST" | cut -d"@" -f2 | tr '[:upper:]' '[:lower:]' \
        | sort | uniq
}

Smtp_probe() {
    local MX="$1"
    local SMTP_PID
    local FIFO="$(mktemp --dry-run)"

    mkfifo --mode 600 "$FIFO"

    # Background SMTP process
    echo -n | nc -w 5 "$MX" 25 > "$FIFO" 2> /dev/null &
    SMTP_PID="$!"

    # FIFO closes automatically

    if grep -q "^220 " < "$FIFO"; then
        #TODO Why kill? "nc -w 5"
        # avoid default notification in non-interactive shell for SIGTERM
        #trap -- "" SIGTERM
        #kill -9 "$SMTP_PID" > /dev/null 2>&1
        #trap SIGTERM
        rm "$FIFO"
        return 0
    else
        # No valid answer from MX in 5 seconds
        rm "$FIFO"
        return 1
    fi
}

# Ping and smtp-probe MX-s
Mx_test() {
    local DOMAIN="$1"
    local RESULT="NO.mx"
    local MX
    local MXS
    local COUNT="0"

    # Ordered by preference number
    MXS="$(timeout 5 host -t MX "$DOMAIN" 2> /dev/null \
        | grep "is handled by" | sort -k6 -n)"

    while read MX; do
        [ -z "$MX" ] && continue

        # Ping
        RESULT="FAIL.ping"
        if ping -c 2 -w 3 "$MX" > /dev/null 2>&1; then
            RESULT="OK.ping+FAIL.smtp"
        fi

        # SMTP
        if Smtp_probe "$MX"; then
            RESULT="OK.smtp"
            # Return only the highest priority + first working MX
            break
        fi
    done <<< "$(echo "$MXS" | grep -o '\S\+\.$')"

    if [ "$RESULT" != "OK.smtp" ]; then
        echo "$RESULT"
        return 1
    fi
}

# Delete message without MX record from the mail queue
Cancel_mailq() {
    local FAILED="$1"
    local D
    local MAILQ="$(mktemp)"

    mailq -batch > "$MAILQ"

    # find pending mails IDs
    while read LINE; do
        D="${LINE%%:*}"
        grep "@${D};" "$MAILQ" | cut -d';' -f 2,4 \
            | while read ID_USER; do
                sudo -u ${ID_USER#*;} -g "$MAIL_GROUP" -- cancelmsg ${ID_USER%;*}
            done
    done < "$FAILED"

    rm "$MAILQ"
}

# empty list
[ -s "$ORIG_LIST" ] || Die 10 "No addresses in the list."

# Clean up the list
[ -f "$CLEAN_LIST" ] || Email_cleanup "$ORIG_LIST" 1> "$CLEAN_LIST" 2> "$LINES_FAILED"
[ -s "$CLEAN_LIST" ] || Die 1 "No addresses in the list after cleanup."

# Extract unique domain names
[ -f "$DOMAIN_LIST" ] || Addr2dom "$CLEAN_LIST" > "$DOMAIN_LIST"
[ -s "$DOMAIN_LIST" ] || Die 2 "No addresses passed the cleanup."

# Test MX-s
[ -f "$SMTP_OK_LIST" ] || while read D; do
    Progress
    if RESULT="$(Mx_test "$D")"; then
        echo "$D" >> "$SMTP_OK_LIST"
    else
        echo "${D}:${RESULT}" >> "$SMTP_FAIL_LIST"
    fi
done < "$DOMAIN_LIST"
[ -s "$SMTP_OK_LIST" ] || Die 3 "None of MX-s are OK."

# Retest failed MX-s
if [ -s "$SMTP_FAIL_LIST" ]; then
    while read FAILED; do
        D="${FAILED%%:*}"
        Progress
        if RESULT="$(Mx_test "$D")"; then
            echo "$D" >> "$SMTP_OK_LIST"
            sed -i "/^${D}:/d" "$SMTP_FAIL_LIST"
        else
            # Remove addresses with 2 times failed domains
            sed -i "/@${D}$/Id" "$CLEAN_LIST"
        fi
    done < "$SMTP_FAIL_LIST"

    [ "$(id --user)" == 0 ] && Cancel_mailq "$SMTP_FAIL_LIST"
fi
