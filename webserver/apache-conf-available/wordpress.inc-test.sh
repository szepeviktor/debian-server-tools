#!/bin/bash
#
# Test wordpress.inc.conf.
#

BASE_URL="http://wpinc.test"

while read -r URL; do
    #URL="${URL/wp-content/static}"
    HEADERS="$(wget -q -S -O /dev/null 2>&1 "${BASE_URL}${URL#+}")"

    printf '%s - ' "$URL"

    if [ "${URL:0:1}" == "+" ]; then
        if grep -E -q -x '  HTTP/(1\.0|1\.1|2\.0) 200 OK' <<<"$HEADERS"; then
            echo "OK."
        else
            echo "$(tput setaf 1)Failed$(tput sgr0)"
        fi
    else
        if grep -E -q -x '  HTTP/(1\.0|1\.1|2\.0) 403 Forbidden' <<<"$HEADERS"; then
            echo "OK."
        else
            echo "$(tput setaf 1)Failed$(tput sgr0)"
        fi
    fi
done <wordpress.inc-test-urls.txt

echo "OK."
