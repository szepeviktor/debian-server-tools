#!/bin/bash
#
# Report Apache errors of the last 24 hours.
#
# VERSION       :1.1.1
# DATE          :2015-12-12
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze recode
# DEPENDS       :/usr/local/bin/dategrep
# LOCATION      :/usr/local/sbin/apache-xreport.sh
# CRON-DAILY    :/usr/local/sbin/apache-xreport.sh

# Use package/dategrep-install.sh

CCZE_CSS_URL="https://szepe.net/wp-ccze/ccze-apache.css"
CCZE_BODY_BG="#fdf6e3"
EMAIL_HEADER="Subject: [admin] HTTP xerrors from $(hostname -f)
From: webserver <root>
To: webmaster@szepe.net
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
"
APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*.conf)"

Xclude_filter() {
    grep -Ev " AH00162:| wpf2b_| bad_request_| no_wp_here_| 404_not_found\
| 403_forbidden| df2b| netpromo_| AH00128:|\sFile does not exist:\
|\sclient denied by server configuration:| Installing seccomp filter failed"
}

Color_html() {
    ccze --html --options "cssfile=${CCZE_CSS_URL}" -c "cssbody=${CCZE_BODY_BG}" \
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
    echo "Apace log files could not be found." 1>&2
    exit 1
fi

# APACHE_LOG_DIR is defined here
source /etc/apache2/envvars

# For non-existent previous log file
shopt -s nullglob

while read CONFIG_FILE; do
    ERROR_LOG="$(sed -n '/^\s*ErrorLog\s\+\(\S\+\)\s*.*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
    SITE_USER="$(sed -n '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "$CONFIG_FILE")"

    # Substitute variables
    ERROR_LOG="$(echo "$ERROR_LOG" | sed \
        -e "s;\${APACHE_LOG_DIR};${APACHE_LOG_DIR};g" \
        -e "s;\${SITE_USER};${SITE_USER};g")"

    # Log lines for 1 day from Debian cron.daily
    nice /usr/local/bin/dategrep --format '%a %b %d %T(.[0-9]+)? %Y' --multiline \
        --from "1 day ago at 06:25:00" --to "06:25:00" "$ERROR_LOG".[1] "$ERROR_LOG" \
        | Xclude_filter \
        | sed "s;^;$(basename "$ERROR_LOG" .log): ;"

done <<< "$APACHE_CONFIGS" | Maybe_sendmail

exit 0
