#!/bin/bash
#
# Report Apache errors of the last 24 hours.
#
# VERSION       :1.4.1
# DATE          :2019-01-25
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze perl dategrep
# LOCATION      :/usr/local/sbin/apache-xreport.sh
# CRON-DAILY    :/usr/local/sbin/apache-xreport.sh

CCZE_CSS_URL="https://cdn.rawgit.com/szepeviktor/debian-server-tools/master/monitoring/apache-ccze.css"
CCZE_BODY_BG="#fdf6e3"
EMAIL_HEADER="Subject: [admin] HTTP xerrors from $(hostname -f)
From: webserver <root>
To: admin@szepe.net
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
"
APACHE_CONFIGS="$(find /etc/apache2/sites-enabled/ -type l -name "*.conf")"

Xclude_filter()
{
    # AH00128: File does not exist
    # #AH00162: server seems busy, (you may need "to increase StartServers, or Min/MaxSpareServers)
    # AH02032: Hostname %s provided via SNI and hostname %s provided via HTTP are different
    # WAF for WordPress
    # Apache access control
    # Apache restart messages at 6 AM
    # Malformed ??? hostname "5e ed 1d 4c bb 01", "5e ed 51 84 bb 01" via SNI
    grep -Ev "\\sAH00128:|\\sAH02032:\
|\\sw4wp_|\\sbad_request_|\\sno_wp_here_|\\s404_not_found|\\s403_forbidden|\\sFile does not exist:\
|\\sclient denied by server configuration:" \
    | grep -Evx '\[.* 06:.* [0-9][0-9][0-9][0-9]\] \[\S+:(info|notice)\] \[pid [0-9]+:tid [0-9]+\] (AH00493|AH00830|AH01887|AH01876|AH03090|AH00489|AH00490|AH00094):.*' \

}

Color_html()
{
    ccze --html --options "cssfile=${CCZE_CSS_URL}" -c "cssbody=${CCZE_BODY_BG}" \
        | perl -MMIME::QuotedPrint -p -e '$_=MIME::QuotedPrint::encode_qp($_);'
}

Maybe_sendmail()
{
    local STRIPPED_BYTE

    read -r -n 1 STRIPPED_BYTE \
        && {
            # stdin is not empty
            echo "$EMAIL_HEADER"
            { echo -n "$STRIPPED_BYTE"; cat; } | Color_html
        } | /usr/sbin/sendmail
}

if [ -z "$APACHE_CONFIGS" ]; then
    echo "Apace log files could not be found." 1>&2
    exit 10
fi

# APACHE_LOG_DIR is defined here
# shellcheck disable=SC1091
source /etc/apache2/envvars

# For non-existent previous log file
shopt -s nullglob

while read -r CONFIG_FILE; do
    ERROR_LOG="$(sed -n -e '/^\s*ErrorLog\s\+\(\S\+\)\s*.*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
    SITE_USER="$(sed -n -e '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "$CONFIG_FILE")"

    # Substitute variables
    ERROR_LOG="$(echo "$ERROR_LOG" | sed \
        -e "s;\${APACHE_LOG_DIR};${APACHE_LOG_DIR};g" \
        -e "s;\${SITE_USER};${SITE_USER};g")"

    # Log lines for 1 day from Debian cron.daily
    nice dategrep --format '%a %b %d %T(.[0-9]+)? %Y' --multiline \
        --start "now truncate 24h add -17h35m" --end "06:25:00" "$ERROR_LOG".[1] "$ERROR_LOG" \
        | Xclude_filter \
        | sed "s;^;$(basename "$ERROR_LOG" .log): ;"

done <<<"$APACHE_CONFIGS" | Maybe_sendmail

exit 0
