#!/bin/bash
#
# Report filtered Apache error logs from yesturday.
#
# VERSION       :1.0.0
# DATE          :2015-07-03
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze recode
# LOCATION      :/usr/local/sbin/apache-errorlog-report.sh
# CRON.D        :02 0	* * *	root	/usr/local/sbin/apache-errorlog-report.sh

# Installation
#
# - Set filter regexp below
# - Rename this script
# - Copy to /usr/local/sbin/
# - Add cron job


EMAIL_ADDREDD="webmaster@szepe.net"
EMAIL_SUBJECT="[ad.min] HTTP error log from $(hostname -f)"
APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*)"
YESTURDAY="$(LC_ALL=C date --date="1 day ago" "+%a %b %d [0-9:.]\\+ %Y")"

if [ -z "$APACHE_CONFIGS" ]; then
    echo "Apace log files could not be found." >&2
    exit 1
fi

# APACHE_LOG_DIR is defined in
source /etc/apache2/envvars

while read CONFIG_FILE; do
    ERROR_LOG="$(sed -n '/^\s*ErrorLog\s\+\(\S\+\)\s*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
    SITE_USER="$(sed -n '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "$CONFIG_FILE")"

    # Substitute variables
    ERROR_LOG="$(echo "$ERROR_LOG"|sed -e "s;\${APACHE_LOG_DIR};${APACHE_LOG_DIR};g" \
        -e "s;\${SITE_USER};${SITE_USER};g")"

    # Filter regexp
    # [Sat Jun 27 19:20:10.050619 2015] [:error] [pid 123] [client 1.2.3.4:61234]
    grep "^\[${YESTURDAY}\] \[.\?error\]\( \[pid [0-9]\+\]\)\? \[client [0-9:.]\+\] .*Permission denied" \
        "$ERROR_LOG" "${ERROR_LOG}.1"

done <<< "$APACHE_CONFIGS" \
    | mailx -E -s "$EMAIL_SUBJECT" "$EMAIL_ADDREDD"
