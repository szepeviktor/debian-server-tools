#!/bin/bash
#
# Check Speedtest Mini expiration time and update it.
#
# VERSION       :0.2.1
# DATE          :2015-08-09
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install swfmill unzip
# LOCATION      :/usr/local/bin/update-speedtest-mini.sh
# CRON-WEEKLY   :/usr/local/bin/update-speedtest-mini.sh

# Set your document root
MINI_PATH="/home/web/website/html/speed"
# Date-style expiration time
MINI_EXPIRE="2 months ago"

# http://www.speedtest.net/mini.php
MINI_URL="http://c.speedtest.net/mini/mini.zip"

Die() {
    local RET="$1"

    shift
    echo -e "$@" >&2
    exit "$RET"
}

Check_expiration() {
    local MODIFY_DATE
    local -i MODIFY_SECONDS="0"
    local -i MONTH_AGO_SECONDS

    if which swfmill &> /dev/null \
        && [ -f "${MINI_PATH}/speedtest.swf" ]; then
        MODIFY_DATE="$(swfmill -e latin1 swf2xml "${MINI_PATH}/speedtest.swf" 2> /dev/null \
            | sed -n 's|^.*<xmp:ModifyDate>\(.*\)</xmp:ModifyDate>.*$|\1|p')"

        if [ -n "$MODIFY_DATE" ]; then
            MODIFY_SECONDS="$(date --date "$MODIFY_DATE" "+%s" 2> /dev/null || echo "0")"
        fi
    fi

    MONTH_AGO_SECONDS="$(date --date="$MINI_EXPIRE" "+%s")"
    # Expired, return with the exit code
    [ "$MODIFY_SECONDS" -lt "$MONTH_AGO_SECONDS" ]
}

Update_mini() {
    local ZIP="$(basename "$MINI_URL")"

    # Limit the download speed (2 MB/s)
    wget -q --limit-rate=2m -O "${MINI_PATH}/${ZIP}" "$MINI_URL" || Die 1 "ZIP download"

    if [ -d "${MINI_PATH}/mini" ]; then
        rm -r "${MINI_PATH}/mini" || Die 2 "Failed to remove old files: ./mini"
    fi
    if [ -d "${MINI_PATH}/speedtest" ]; then
        rm -r "${MINI_PATH}/speedtest" || Die 3 "Failed to remove old files: ./speedtest"
    fi

    unzip -q "${MINI_PATH}/${ZIP}" -d "${MINI_PATH}/" || Die 4 "Extraction failed."
    rm "${MINI_PATH}/${ZIP}" || Die 5 "ZIP cannot be removed."

    mv "${MINI_PATH}/mini/speedtest.swf" "${MINI_PATH}/" || Die 6 "Flash file cannot be moved in place."
    mv "${MINI_PATH}/mini/speedtest" "${MINI_PATH}/" || Die 7 "Payload files cannot be moved in place."
    mv "${MINI_PATH}/mini/crossdomain.xml" "${MINI_PATH}/" || Die 8 "crossdomain.xml cannot be moved in place."
    mv "${MINI_PATH}/mini/index-php.html" "${MINI_PATH}/index.php" || Die 9 "Index file cannot be moved in place."

    rm -r "${MINI_PATH}/mini" || Die 10 "Failed to remove unnecassary files."
    find "${MINI_PATH}" -type f -exec chmod -x "{}" ";" || Die 11 "Failed to turn off execution bit."
}

Check_expiration && Update_mini

exit 0
