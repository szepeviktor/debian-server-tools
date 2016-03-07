#!/bin/bash
#
# Check front page of a website.
#

# CRON.D        :02 *	* * *	web	/usr/local/bin/frontpage-check.sh CONFIG-FILE

SITE_CONFIG="$1"
#FPCHK_WEBSITE_NAME=""
#FPCHK_URL=""
#FPCHK_EXCLUDE_PARTS_REGEX=''
#FPCHK_CHKSUM=""
#FPCHK_CHKSUM_GOOGLE_REFERER=""
#FPCHK_UA=""

# Default values
FPCHK_UA="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:35.0) Gecko/20100101 Firefox/35.0"

[ -r "$SITE_CONFIG" ] || exit 1
source "$SITE_CONFIG"

# Static file
SITE-URL/wp-includes/wlwmanifest.xml | grep -qF '<serviceName>WordPress</serviceName>'

# PHP version and MySQL version and server time
"SITE-URL/ping.php?time=$(date "+%s")" | grep -qFx 'MD5-SUM'

Get_content firefox.sh $frontpage

# Front page MySQL, PHP and webserver errors
FRONT-PAGE | grep -qEi 'PHP \S+: |MySQL|error|notice|warning|Account.*Suspend'

# Front page title
FRONT-PAGE | grep -q '<h1>Title string'

# Front page content checksum
if ! wget -qO- --max-redirect=0 --timeout=5 --user-agent="$FPCHK_UA" \
    "$FPCHK_URL" \
    | sed "s|${FPCHK_EXCLUDE_PARTS_REGEX}||" \
    | md5sum | grep -q "$FPCHK_CHKSUM"; then
    echo "${FPCHK_WEBSITE_NAME}/frontpage checksum error" >&2
fi

# Front page content checksum with Google referer
if ! wget -qO- --max-redirect=0 --timeout=5 --referer="https://www.google.com/" --user-agent="$FPCHK_UA" \
    "$FPCHK_URL" \
    | sed "s|${FPCHK_EXCLUDE_PARTS_REGEX}||" \
    | md5sum | grep -q "$FPCHK_CHKSUM_GOOGLE_REFERER"; then
    echo "${FPCHK_WEBSITE_NAME}/frontpage-from-google checksum error" >&2
fi

# Front page screenshot - http://phantomjs.org/screen-capture.html
