#!/bin/bash
#
# Report filtered Apache error logs from yesturday.
#
# VERSION       :1.1.3
# DATE          :2015-07-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze recode
# LOCATION      :/usr/local/sbin/apache-errorlog-report.sh
# CRON-DAILY    :/usr/local/sbin/apache-errorlog-report.sh

# Installation
#
# Download the dategrep binary directly from GitHub (without package management)
#
#     apt-get install -y libdate-manip-perl
#     R="$(wget -qO- https://api.github.com/repos/mdom/dategrep/releases|sed -n '0,/^.*"tag_name": "\([0-9.]\+\)".*$/{s//\1/p}')"
#     wget -O /usr/local/bin/dategrep https://github.com/mdom/dategrep/releases/download/${R}/dategrep-standalone-small
#     chmod +x /usr/local/bin/dategrep
#
# - Set filter regexp in Filter_log()
# - Set email recipient and subject
# - Copy to /usr/local/sbin/apache-errorlog-CUSTOM-NAME.sh
# - And add cron job

EMAIL_ADDRESS="webmaster@szepe.net"
EMAIL_SUBJECT="[ad.min] HTTP error log from $(hostname -f)"
APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*)"

Filter_log() {
    grep "\[client [0-9:.]\+\] .*Permission denied"
}

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

    # Filter error log with regexp for 1 day from cron.daily
    # [Sat Jun 27 19:20:10.050619 2015] [:error] [pid 123] [client 1.2.3.4:61234]
    ionice -c 3 /usr/local/bin/dategrep --format '%a %b %d %T(\.[0-9]+)? %Y' --multiline \
        --from "1 day ago at 06:25:00" --to "06:25:00" "${ERROR_LOG}.1" "$ERROR_LOG" \
        | Filter_log \
        | sed "s;^;$(basename "$ERROR_LOG" .log): ;g"

done <<< "$APACHE_CONFIGS" \
    | mailx -E -s "$EMAIL_SUBJECT" "$EMAIL_ADDRESS"
