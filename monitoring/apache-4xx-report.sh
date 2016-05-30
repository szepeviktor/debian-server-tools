#!/bin/bash
#
# Report Apache client and server errors of the last 24 hours.
#
# VERSION       :1.2.3
# DATE          :2015-11-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze recode
# DEPENDS       :/usr/local/bin/dategrep
# LOCATION      :/usr/local/sbin/apache-4xx-report.sh
# CRON-DAILY    :/usr/local/sbin/apache-4xx-report.sh

# Use package/dategrep-install.sh

CCZE_CSS_URL="https://szepe.net/wp-ccze/ccze-apache.css"
CCZE_BODY_BG="#fdf6e3"
EMAIL_HEADER="Subject: [admin] HTTP client errors from $(hostname -f)
To: webmaster@szepe.net
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
"
APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*.conf)"

Filter_client_server_error() {
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4
    # 1.2.3.4 - - [27/Jun/2015:14:35:41 +0200] "GET /request-uri HTTP/1.1" 404 1234 "-" "User-agent/1.1"
    grep -E '" (4(0[0-9]|1[0-7])|50[0-5]) [0-9]+ "'
}

Color_html() {
    ccze --plugin httpd --html --options "cssfile=${CCZE_CSS_URL}" -c "cssbody=${CCZE_BODY_BG}" \
        | recode -f UTF-8..UTF-8/QP
}

Maybe_sendmail() {
    local STRIPPED_BYTE

    read -n 1 STRIPPED_BYTE \
        && {
            # stdin is not empty
            echo "$EMAIL_HEADER"
            { echo -n "$STRIPPED_BYTE"; cat; } | Color_html
        } | /usr/sbin/sendmail
}

if [ -z "$APACHE_CONFIGS" ]; then
    echo "Apace log files could not be found." >&2
    exit 1
fi

# APACHE_LOG_DIR is defined here
source /etc/apache2/envvars

# For non-existent previous log file
shopt -s nullglob

while read -r CONFIG_FILE; do
    ACCESS_LOG="$(sed -n -e '/^\s*CustomLog\s\+\(\S\+\)\s\+\S\+.*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
    SITE_USER="$(sed -n -e '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "$CONFIG_FILE")"

    # Substitute variables
    # @TODO Prevent double log processing -> remember processed log files
    ACCESS_LOG="$(echo "$ACCESS_LOG" | sed \
        -e "s;\${APACHE_LOG_DIR};${APACHE_LOG_DIR};g" \
        -e "s;\${SITE_USER};${SITE_USER};g")"

    # Log lines for 1 day from Debian cron.daily
    nice /usr/local/bin/dategrep --format apache --multiline \
        --from "1 day ago at 06:25:00" --to "06:25:00" "$ACCESS_LOG".[1] "$ACCESS_LOG" \
        | Filter_client_server_error \
        | sed "s;^;$(basename "$ACCESS_LOG" .log): ;"

done <<< "$APACHE_CONFIGS" | Maybe_sendmail

exit 0
