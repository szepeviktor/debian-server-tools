#!/bin/bash
#
# Check front page of a website.
#

# CRON.D        :02 *	* * *	nobody	/usr/local/bin/frontpage-check.sh CONFIG-FILE

SITE_CONFIG="$1"
#FPCHK_WEBSITE_NAME=""
#FPCHK_URL=""
#FPCHK_EXCLUDE_PARTS_REGEX=''
#FPCHK_CHKSUM=""
#FPCHK_CHKSUM_GOOGLE_REFERER=""
#FPCHK_UA=""

# Default values
FPCHK_UA="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:35.0) Gecko/20100101 Firefox/35.0"

test -r "$SITE_CONFIG" || exit 1
# shellcheck disable=SC1090
source "$SITE_CONFIG"

# Static file
wget -q -O- "SITE-URL/wp-includes/wlwmanifest.xml" | grep -q -F '<serviceName>WordPress</serviceName>'

# PHP version and MySQL version and server time
wget -q -O- "SITE-URL/ping.php?time=$(date "+%s")" | grep -q -F -x 'MD5-SUM'

Get_content firefox.sh "FRONT-PAGE"

# Front page MySQL, PHP and webserver errors
wget -q -O- "FRONT-PAGE" | grep -q -E -i 'PHP \S+: |MySQL|error|notice|warning|Account.*Suspend'

# Front page title
wget -q -O- "FRONT-PAGE" | grep -q '<h1>Title string'

# Front page content checksum
if ! wget -q -O- --max-redirect=0 --timeout=5 --user-agent="$FPCHK_UA" \
    "FRONT-PAGE" \
    | sed -e "s#${FPCHK_EXCLUDE_PARTS_REGEX}##" \
    | md5sum | grep -q "$FPCHK_CHKSUM"; then
    echo "${FPCHK_WEBSITE_NAME}/frontpage checksum error" 1>&2
fi

# Front page content checksum with Google referer
if ! wget -q -O- --max-redirect=0 --timeout=5 --referer="https://www.google.com/" --user-agent="$FPCHK_UA" \
    "FRONT-PAGE" \
    | sed -e "s#${FPCHK_EXCLUDE_PARTS_REGEX}##" \
    | md5sum | grep -q "$FPCHK_CHKSUM_GOOGLE_REFERER"; then
    echo "${FPCHK_WEBSITE_NAME}/frontpage-from-google checksum error" 1>&2
fi

# Front page screenshot - http://phantomjs.org/screen-capture.html
