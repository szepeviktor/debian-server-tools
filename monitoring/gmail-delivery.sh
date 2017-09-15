#!/bin/bash
#
# Check delivery to Gmail.
#
# VERSION       :0.1.1
# DATE          :2017-09-14
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install apg fetchmail
# DOCS          :https://support.google.com/mail/answer/7104828
# LOCATION      :/usr/local/sbin/gmail-delivery.sh
# OWNER         :root:nobody
# PERMISSION    :0750
# CRON.D        :02 *	* * *	root	/usr/local/sbin/gmail-delivery.sh

# EDIT
PROVIDER="SparkPost"
FROM_FULL="nobody <nobody@>"
GMAIL_ACCOUNT="@gmail.com"
GMAIL_PWD=""
# Seconds to wait for delivery
declare -i THRESHOLD="60"

Alert() {
    logger -t "gmail-delivery" "$*"
    echo "$*" | mail -s "Gmail delivery failure on $(hostname -f)" admin@szepe.net

    exit 10
}

Send() {
    # Random words
    apg -n 30 -m 3 -x 12 | paste -s -d " " \
        | mail -s "delivery through ${PROVIDER}" "$GMAIL_ACCOUNT"
}

Fetch() {
    # Max 1 message per fetch
    fetchmail --silent --fetchmailrc - --idfile /tmp/nobody-fetchids --pidfile /tmp/nobody-fetchmail.pid <<EOF
poll pop.gmail.com protocol POP3
    username "${GMAIL_ACCOUNT}" password "${GMAIL_PWD}"
    ssl sslcertck fetchlimit 1
    mda "${SELF} %F ${TEMP_FILE}"
EOF
}

Mda() {
    local FROM="$1"
    local TEMP_FILE="$2"

    if [ ! -r "$TEMP_FILE" ]; then
        Alert "Temporary file does not exist"
        # We tell fetchmail it is OK.
        cat > /dev/null
        exit 0
    fi

    { echo "From ${FROM}"; cat; } > "$TEMP_FILE"
}

Check() {
    Fetch || Alert "Fetch failed"
    head -n 1 "$TEMP_FILE" | grep -q '^From ' || Alert "Message missing"

    grep -q -F -x "From: ${FROM_FULL}" "$TEMP_FILE" || Alert "From header mismatch"
    grep -q -F -x "To: ${GMAIL_ACCOUNT}" "$TEMP_FILE" || Alert "To header mismatch"
    grep -q -F -x "Subject: delivery through ${PROVIDER}" "$TEMP_FILE" || Alert "Subject mismatch"
}

set -e

# Receive mode: fetchmail --mda $SELF
if [ -n "$1" ]; then
    Mda "$@"
    exit
fi

SELF="$(realpath "${BASH_SOURCE[0]}")"
TEMP_FILE="$(mktemp --suffix=.gmail-delivery)"

Send
sleep "$THRESHOLD"
Check
rm "$TEMP_FILE"

exit 0
