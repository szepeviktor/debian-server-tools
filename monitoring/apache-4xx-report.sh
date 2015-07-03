#!/bin/bash
#
# Report Apache client errors from yesturday.
#
# VERSION       :1.0.0
# DATE          :2015-06-27
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze recode
# LOCATION      :/usr/local/sbin/apache-4xx-report.sh
# CRON.D        :00 0	* * *	root	/usr/local/sbin/apache-4xx-report.sh

CCZE_CSS_URL="https://szepe.net/wp-ccze/ccze-apache.css"
CCZE_BODY_BG="#fdf6e3"
EMAIL_HEADER="Subject: [admin] HTTP client errors from $(hostname -f)
To: webmaster@szepe.net
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
"
APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*)"
YESTURDAY="$(LC_ALL=C date --date="1 day ago" "+%d/%b/%Y")"

Color_html() {
    ccze --plugin httpd --html --options "cssfile=${CCZE_CSS_URL}" -c "cssbody=${CCZE_BODY_BG}" \
        | recode -f UTF-8..UTF-8/QP
}

if [ -z "$APACHE_CONFIGS" ]; then
    echo "Apace log files could not be found." >&2
    exit 1
fi

# APACHE_LOG_DIR is defined here
source /etc/apache2/envvars

while read CONFIG_FILE; do
    # @TODO First log file only
    ACCESS_LOG="$(sed -n '/^\s*CustomLog\s\+\(\S\+\)\s\+\S\+.*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
    SITE_USER="$(sed -n '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "$CONFIG_FILE")"

    # Substitute variables
    ACCESS_LOG="$(echo "$ACCESS_LOG"|sed -e "s;\${APACHE_LOG_DIR};${APACHE_LOG_DIR};g" \
        -e "s;\${SITE_USER};${SITE_USER};g")"

    # Client errors 400-417 from the current and the previous log
    #     http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4
    # 1.2.3.4 - - [27/Jun/2015:14:35:41 +0200] "GET /server-status HTTP/1.1" 404 8308 "-" "Monit/5.10"
    grep " \[${YESTURDAY}:[0-9][0-9]:[0-9][0-9]:[0-9][0-9] .*\" 4\(0[0-9]\|1[0-7]\) [0-9]\+ \"" \
        "$ACCESS_LOG" "${ACCESS_LOG}.1"
done <<< "$APACHE_CONFIGS" \
    | {
        read -n 1 STRIPPED_BYTE \
            && {
                # stdin is not empty
                echo "$EMAIL_HEADER"
                { echo -n "$STRIPPED_BYTE"; cat; } | Color_html
            } | /usr/sbin/sendmail
    }
