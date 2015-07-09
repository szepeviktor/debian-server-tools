#!/bin/bash
#
# Report Apache client errors of the last 24 hours.
#
# VERSION       :1.1.2
# DATE          :2015-07-06
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze recode
# LOCATION      :/usr/local/sbin/apache-4xx-report.sh
# CRON-DAILY    :/usr/local/sbin/apache-4xx-report.sh

# Download the dategrep binary directly from GitHub (without package management)
#
#     apt-get install -y libdate-manip-perl
#     R="$(wget -qO- https://api.github.com/repos/mdom/dategrep/releases|sed -n '0,/^.*"tag_name": "\([0-9.]\+\)".*$/s//\1/p')"
#     wget -O /usr/local/bin/dategrep https://github.com/mdom/dategrep/releases/download/${R}/dategrep-standalone-small
#     chmod +x /usr/local/bin/dategrep

CCZE_CSS_URL="https://szepe.net/wp-ccze/ccze-apache.css"
CCZE_BODY_BG="#fdf6e3"
EMAIL_HEADER="Subject: [admin] HTTP client errors from $(hostname -f)
To: webmaster@szepe.net
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
"
APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*)"

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

while read CONFIG_FILE; do
    ACCESS_LOG="$(sed -n '/^\s*CustomLog\s\+\(\S\+\)\s\+\S\+.*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
    SITE_USER="$(sed -n '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "$CONFIG_FILE")"

    # Substitute variables
    ACCESS_LOG="$(echo "$ACCESS_LOG"|sed -e "s;\${APACHE_LOG_DIR};${APACHE_LOG_DIR};g" \
        -e "s;\${SITE_USER};${SITE_USER};g")"

    # Client errors 400-417 for 1 day from cron.daily
    #     http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4
    # 1.2.3.4 - - [27/Jun/2015:14:35:41 +0200] "GET /request-uri HTTP/1.1" 404 1234 "-" "User-agent/1.1"
    ionice -c 3 /usr/local/bin/dategrep --format apache --multiline \
        --from "1 day ago at 06:25:00" --to "06:25:00" "${ACCESS_LOG}.1" "$ACCESS_LOG" \
        | grep "\" 4\(0[0-9]\|1[0-7]\) [0-9]\+ \"" \
        | sed "s;^;$(basename "$ACCESS_LOG" .log): ;g"
done <<< "$APACHE_CONFIGS" | Maybe_sendmail
