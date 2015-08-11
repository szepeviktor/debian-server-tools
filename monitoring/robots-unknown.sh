#!/bin/bash
#
# Report traffic from unknown robots.
#

# http://smythies.com/robots.txt
#
# Authorized robots 10+
#
#     grep "GET /robots\.txt" /home/*/log/access*.log /var/log/apache2/access*.log \
#         |cut -d'"' -f6|sort|uniq -c|sort -n|grep "^\s*[0-9]\{2,\}"
#
# Robots without user agent
#
#     grep ' "-"$' /home/*/log/access*.log /var/log/apache2/access*.log|most

EMAIL_ADDRESS="webmaster@szepe.net"
EMAIL_SUBJECT="[admin] Unknown robots from $(hostname -f)"
APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*)"

Filter_ua() {
    cut -d'"' -f6- \
    | grep -v "^-\"$\|^Mozilla/5\.0 .* Firefox/\|^Mozilla/5\.0 .* AppleWebKit/\|^Mozilla/[4-5]\.0 .* MSIE\
\|^Mozilla/5\.0 .* Trident/7.0\|^Opera/[8-9]\.[0-9]* .* Presto/" \
    | grep -E -v "Googlebot|Googlebot-Image|Feedfetcher-Google|AdsBot-Google|Googlebot-Mobile|bingbot\
|BingPreview|msnbot|MJ12bot|AhrefsBot|YandexBot|YandexImages|yandex\.com/bots|ia_archiver|Baiduspider|Yahoo\! Slurp\
|Pingdom\.com_bot|zerigo\.com/watchdog|ClickTale bot|facebookexternalhit|Wget|Feedstripes" \
    | grep -E -v "Amazon CloudFront|Debian APT-HTTP|munin/2\.0\.6|W3 Total Cache"
}

Digest_ua() {
    sort | uniq -c | sort -g | grep "^\s*[0-9]\{3,\}"
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

    ionice -c 3 /usr/local/bin/dategrep --format apache --multiline \
        --from "1 day ago at 06:25:00" --to "06:25:00" "${ACCESS_LOG}.1" "$ACCESS_LOG"

done <<< "$APACHE_CONFIGS" \
    | Filter_ua \
    | Digest_ua \
    | sed 's;^;|;' \
    | mailx -E -S from="robots unknown <root>" -s "$EMAIL_SUBJECT" "$EMAIL_ADDRESS"
