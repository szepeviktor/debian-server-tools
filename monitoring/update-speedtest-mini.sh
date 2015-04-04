#!/bin/bash
#
# Check Speedtest Mini script's expiration and update it.
#
# VERSION       :0.2
# DATE          :2015-04-03
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install swfmill
# LOCATION      :/usr/local/bin/update-speedtest-mini.sh
# CRON-WEEKLY   :/usr/local/bin/update-speedtest-mini.sh

# Set your web root here:
MINI_PATH="/var/www/subdirwp/server/speed"

# http://www.speedtest.net/mini.php
MINI_URL="http://c.speedtest.net/mini/mini.zip"
# date-style expiration
MINI_EXPIRE="2 months ago"

Die() {
    local RET="$1"
    shift
    echo -e $@ >&2
    exit "$RET"
}

Check_expiration() {
    local MODIFY_DATE
    local -i MODIFY_SECONDS
    local -i MONTH_AGO

    if [ -f "${MINI_PATH}/speedtest.swf" ] \
        && which swfmill &> /dev/null; then
        MODIFY_DATE="$(swfmill -e latin1 swf2xml "${MINI_PATH}/speedtest.swf" 2> /dev/null \
            |sed -n 's|^.*<xmp:ModifyDate>\(.*\)</xmp:ModifyDate>.*$|\1|p')"

        if [ -z "$MODIFY_DATE" ]; then
            #Die 1 "ModifyDate extraction failure."
            MODIFY_SECONDS="0"
        else
            MODIFY_SECONDS="$(date --date "$EXPIRE" --utc +%s 2> /dev/null)"
            if [ -z "$MODIFY_SEC" ]; then
                #Die 2 "Invalid ModifyDate."
                MODIFY_SECONDS="0"
            fi
        fi
    else
        #Die 3 "Flash file is missing. / Missing dependencies."
        MODIFY_SECONDS="0"
    fi

    # older than MINI_EXPIRE
    MONTH_AGO="$(date --utc --date="$MINI_EXPIRE" +%s)"
    if [ "$MODIFY_SECONDS" -lt "$MONTH_AGO" ]; then
        Update_mini
    fi
}

Update_mini() {
    local ZIP="$(basename "$MINI_URL")"

    wget -q --limit-rate=10m -O "${MINI_PATH}/${ZIP}" "$MINI_URL" || Die 1 "ZIP download"

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
    find "${MINI_PATH}" -type f -exec chmod -x \{\} \; || Die 11 "Failed to turn off execution bit."
}

Check_expiration
