#!/bin/bash
#
# Can-send-email triggers and checks in one.
#
# VERSION       :1.0.0
# DATE          :2015-06-13
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mailx
# LOCATION      :/usr/local/sbin/can-send-email.sh
# CRON.D        :40 */6	* * *	daemon	/usr/local/sbin/can-send-email.sh --trigger
# CRON.D        :50 */6	* * *	daemon	/usr/local/sbin/can-send-email.sh --check

ALERT_ADDRESS="viktor@szepe.net"
WORK_DIR="/var/lib/can-send-email"
# 6 hours in seconds
FAILURE_INTERVAL="$((6 * 3600))"

HTTP_USER_AGENT="Can-send-email/1.0 (bash; Linux)"
# UTC
NOW="$(date "+%s")"

# stderr goes to SMTP
Error() {
    local RET="$1"

    shift
    echo "ERROR: $*" 1>&2
    exit "$RET"
}

Sql() {
    sqlite3 "${WORK_DIR}/cse.sqlite3" "$(printf "$@")"
}

Init() {
    install -v -D \
        --owner="daemon" --group="daemon" --mode "600" \
        --target-directory "$WORK_DIR" ./cse.sqlite3
    Sql 'CREATE TABLE host ( "id" INTEGER PRIMARY KEY, "hostname" TEXT, "url" TEXT, "last" DATETIME );' \
        && echo "OK."
}

Is_host() {
    local HOSTNAME="$1"

    Sql 'SELECT "id" FROM host WHERE "hostname" = "%s";' \
        "$HOSTNAME"
}

Add_host() {
    local HOSTNAME="$1"
    local URL="$2"

    if [ -z "$HOSTNAME" ] || [ -z "$URL" ]; then
        Error 3 "Usage: $0 --add SERVERNAME URL"
    fi
    if [ -n "$(Is_host "$HOSTNAME")" ]; then
        Error 4 "Host already exists!"
    fi

    Sql 'REPLACE INTO host ( "hostname", "url", "last" ) VALUES ( "%s", "%s", "%s" );' \
        "$HOSTNAME" "$URL" "$NOW"
}

Remove_host() {
    local HOSTNAME="$1"

    if [ -z "$HOSTNAME" ]; then
        Error 5 "Usage: $0 --remove HOSTNAME"
    fi
    if [ -z "$(Is_host "$HOSTNAME")" ]; then
        Error 6 "Host does not exist!"
    fi

    Sql 'DELETE FROM host WHERE "hostname" = "%s";' \
        "$HOSTNAME"
}

List_hosts() {
    Sql 'SELECT "hostname", "url", "last" FROM host;'
}

Update_last() {
    local HOSTNAME="$1"
    local LAST="$2"

    if [ -z "$(Is_host "$HOSTNAME")" ]; then
        logger -t "can-send-email" "Host not found '${HOSTNAME}'"
        echo "501 Syntax error in parameters or arguments"
        return 0
    fi
    Sql 'UPDATE host SET "last" = "%s" WHERE "hostname" = "%s";' \
        "$LAST" "$HOSTNAME" \
        || logger -t "can-send-email" "Update failed for host: '${HOSTNAME}'"
}

Get_urls() {
    Sql 'SELECT "url" FROM host;'
}

Get_failures() {
    Sql 'SELECT "hostname" FROM host WHERE "last" < ( "%s" - "%s" );' \
        "$NOW" "$FAILURE_INTERVAL"
}

case "$1" in
    # Initialize
    "--init")
        Init
        ;;

    # List hosts
    "--list")
        List_hosts
        ;;

    # Add new host
    "--add")
        shift
        Add_host "$@"
        ;;

    # Remove host
    "--remove")
        shift
        Remove_host "$@"
        ;;

    # Trigger emails cron job
    "--trigger")
        Get_urls \
            | wget -q -O- --max-redirect=0 --tries=1 --timeout=5 --user-agent="$HTTP_USER_AGENT" \
                -i - 1>&2
        ;;

    # Check failures cron job
    "--check")
        FAILURES="$(Get_failures)"
        if [ -n "$FAILURES" ]; then
            echo "Failures: ${FAILURES}" | mailx -s "Can-send-email failure" "$ALERT_ADDRESS"
            logger -t "can-send-email" "Can-send-email failures: ${FAILURES}"
            Error 10 "Failures: ${FAILURES}"
        fi
        ;;

    # Receive message
    "")
        MSG_TMP="$(tempfile -d "$WORK_DIR")"
        trap "rm '$MSG_TMP' &> /dev/null" EXIT

        cat > "$MSG_TMP"

        HOSTNAME="$(grep -m1 -x "X-Host: \S\+" "$MSG_TMP")"

        if grep -q "^Subject: \[cse\]" "$MSG_TMP" \
            && [ -n "$HOSTNAME" ]; then
            HOSTNAME="${HOSTNAME#X-Host: }"
            Update_last "$HOSTNAME" "$NOW"
            exit
        fi

        # Invalid email, spam?
        MSG_PATH="${WORK_DIR}/$(date --utc "+%Y%m%d-%H%M%S")_${RANDOM}.eml"
        cp "$MSG_TMP" "$MSG_PATH"
        echo -e "\nX-SMTP-Recipient: ${RECIPIENT}\nX-SMTP-Sender: ${SENDER}\n" >> "$MSG_PATH"
        logger -t "can-send-email" "Invalid email headers in ${MSG_PATH}"
        echo "501 Syntax error in parameters or arguments"
        ;;
esac
