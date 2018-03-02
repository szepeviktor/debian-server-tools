#!/bin/bash
#
# Report Apache client and server errors of the last 24 hours.
#
# VERSION       :1.3.3
# DATE          :2017-03-05
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze perl
# DEPENDS       :/usr/local/bin/dategrep
# LOCATION      :/usr/local/sbin/apache-4xx-report.sh
# CRON-DAILY    :/usr/local/sbin/apache-4xx-report.sh

# Use package/dategrep-install.sh

CCZE_CSS_URL="https://cdn.rawgit.com/szepeviktor/debian-server-tools/master/monitoring/apache-ccze.css"
CCZE_BODY_BG="#fdf6e3"
EMAIL_HEADER="Subject: [admin] HTTP client errors from $(hostname -f)
From: webserver <root>
To: admin@szepe.net
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
"
APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*.conf)"

Filter_client_server_error() {
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4
    # 1.2.3.4 - - [27/Jun/2015:14:35:41 +0200] "GET /request-uri HTTP/1.1" 404 1234 "-" "User-agent/1.1"
    grep -E '" (4(0[0-9]|1[0-7])|50[0-5]) [0-9]+ "' \
        | grep -v -E ' - - \[\S+ \S+\] "-" 408 [[:digit:]]+ "-" "-(\|Host:-)?"$' \
        | grep -v -E '"GET /(ogShow\.aspx|show\.aspx|ogPipe\.aspx).* "Amazon CloudFront"' \

}

Color_html() {
    ccze --plugin httpd --html --options "cssfile=${CCZE_CSS_URL}" -c "cssbody=${CCZE_BODY_BG}" \
        | perl -MMIME::QuotedPrint -p -e '$_=MIME::QuotedPrint::encode_qp($_);'
}

Maybe_sendmail() {
    local STRIPPED_BYTE

    read -r -n 1 STRIPPED_BYTE \
        && {
            # stdin is not empty
            echo "$EMAIL_HEADER"
            { echo -n "$STRIPPED_BYTE"; cat; } | Color_html
        } | /usr/sbin/sendmail
}

In_array() {
    local NEEDLE="$1"
    local ELEMENT

    shift

    for ELEMENT; do
        if [ "$ELEMENT" == "$NEEDLE" ]; then
            return 0
        fi
    done

    return 1
}

declare -a PROCESSED_LOGS

if [ -z "$APACHE_CONFIGS" ]; then
    echo "Apace log files could not be found." 1>&2
    exit 1
fi

# APACHE_LOG_DIR is defined here
# shellcheck disable=SC1091
source /etc/apache2/envvars

# For non-existent previous log file
shopt -s nullglob

while read -r CONFIG_FILE; do
    ACCESS_LOG="$(sed -n -e '/^\s*CustomLog\s\+\(\S\+\)\s\+\S\+.*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
    SITE_USER="$(sed -n -e '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
    # Substitute variables
    ACCESS_LOG="$(echo "$ACCESS_LOG" | sed \
        -e "s;\${APACHE_LOG_DIR};${APACHE_LOG_DIR};g" \
        -e "s;\${SITE_USER};${SITE_USER};g")"

    # Prevent double log processing
    if In_array "$ACCESS_LOG" "${PROCESSED_LOGS[@]}"; then
        continue
    fi
    PROCESSED_LOGS+=( "$ACCESS_LOG" )

    # Log lines for 1 day from Debian cron.daily
    nice /usr/local/bin/dategrep --format apache --multiline \
        --from "1 day ago at 06:25:00" --to "06:25:00" "$ACCESS_LOG".[1] "$ACCESS_LOG" \
        | Filter_client_server_error \
        | sed "s;^;$(basename "$ACCESS_LOG" .log): ;"

done <<< "$APACHE_CONFIGS" | Maybe_sendmail

exit 0
