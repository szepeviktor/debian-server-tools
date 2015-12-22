#!/bin/bash
#
# Report Apache errors of the last 24 hours.
#
# VERSION       :1.1.0
# DATE          :2015-12-12
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze recode
# LOCATION      :/usr/local/sbin/apache-xreport.sh
# CRON-DAILY    :/usr/local/sbin/apache-xreport.sh

# Download the dategrep binary directly from GitHub (without package management)
#
#     apt-get install -y libdate-manip-perl
#     R="$(wget -qO- https://api.github.com/repos/mdom/dategrep/releases|sed -n '0,/^.*"tag_name": "\([0-9.]\+\)".*$/{s//\1/p}')"
#     wget -O /usr/local/bin/dategrep https://github.com/mdom/dategrep/releases/download/${R}/dategrep-standalone-small
#     chmod +x /usr/local/bin/dategrep

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
    grep -Ev " AH00162:| wpf2b_| bad_request_| no_wp_here_| 404_not_found| 403_forbidden| df2b| netpromo_| AH00128:|\sFile does not exist:|\sclient denied by server configuration:| Installing seccomp filter failed"
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
    echo "Apace log files could not be found." >&2
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

    # Log lines for 1 day from cron.daily
    nice /usr/local/bin/dategrep --format '%a %b %d %T(.[0-9]+)? %Y' --multiline \
        --from "1 day ago at 06:25:00" --to "06:25:00" "$ERROR_LOG".[1] "$ERROR_LOG" \
        | Xclude_filter \
        | sed "s;^;$(basename "$ERROR_LOG" .log): ;"

done <<< "$APACHE_CONFIGS" | Maybe_sendmail

exit 0
