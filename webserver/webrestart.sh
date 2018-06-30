#!/bin/bash
#
# Reload PHP-FPM and Apache dependently.
#
# VERSION       :0.6.6
# DATE          :2016-08-26
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install php7.2-fpm apache2
# LOCATION      :/usr/local/sbin/webrestart.sh
# SYMLINK       :/usr/local/sbin/webreload.sh

Error() {
    echo "ERROR: $1" 1>&2
    exit 1
}

# APACHE_RUN_USER is defined here
# shellcheck disable=SC1091
source /etc/apache2/envvars

# PHP-PFM config test
if hash php5-fpm 2> /dev/null; then
    php5-fpm -t || Error "PHP-FPM 5 configuration test failed"
elif hash php-fpm7.0 2> /dev/null; then
    php-fpm7.0 -t || Error "PHP-FPM 7.0 configuration test failed"
elif hash php-fpm7.1 2> /dev/null; then
    php-fpm7.1 -t || Error "PHP-FPM 7.1 configuration test failed"
elif hash php-fpm7.2 2> /dev/null; then
    php-fpm7.2 -t || Error "PHP-FPM 7.2 configuration test failed"
else
    Error "Unknown PHP version"
fi
echo "-----"

APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*.conf)"
while read -r CONFIG_FILE; do
    DOCROOT_MISSING="$(grep '^\s*<VirtualHost\|^\s*DocumentRoot' "$CONFIG_FILE" | sed -n -e '/VirtualHost/n;/DocumentRoot/!p')"
    if [ -n "$DOCROOT_MISSING" ]; then
        Error "Missing DocumentRoot directive in ${CONFIG_FILE}"
    fi

    if [ -f /etc/apache2/mods-enabled/mpm_event.load ]; then
        SITE_USER="$(sed -n -e '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
        if [ -n "$SITE_USER" ]; then
            # Is Apache in this user's group?
            groups "$APACHE_RUN_USER" | cut -d ":" -f 2- | tr '\n' ' ' \
                | grep -q -F " ${SITE_USER} " || Error "Apache is not in ${SITE_USER} group"
        fi
    fi
done <<< "$APACHE_CONFIGS"

# Check non-SNI vhost
if [ -f /etc/apache2/mods-enabled/ssl.load ]; then
    for VHOST in /etc/apache2/sites-enabled/001-*.conf; do
        if [ ! -f "$VHOST" ]; then
            echo "WARNING: Rename non-SNI vhost symlink to '001-site.conf'" 2>&1
        fi
    done
fi

# Check robots.txt
ROBOTS_URLS="$(apache2ctl -S | sed -n -e '/namevhost localhost/d' \
    -e 's|^\s\+port 80 namevhost \(\S\+\) (.*)$|http://\1/robots.txt|p' \
    -e 's|^\s\+port 443 namevhost \(\S\+\) (.*)$|https://\1/robots.txt|p')"
while read -r ROBOTS_URL; do
    echo -n "."
    wget -t 1 -q -O - "$ROBOTS_URL" | grep -q -i '^User-agent:' \
        || Error "robots.txt is not set up (${ROBOTS_URL})"
done <<< "$ROBOTS_URLS"
echo

# Apache config test
apache2ctl configtest || Error "Apache configuration test"
echo "-----"

# Reload!
if hash php5-fpm 2> /dev/null; then
    service php5-fpm reload || Error 'PHP-FPM 5 reload failed, ACT NOW!'
elif hash php-fpm7.0 2> /dev/null; then
    service php7.0-fpm reload || Error 'PHP-FPM 7.0 reload failed, ACT NOW!'
elif hash php-fpm7.1 2> /dev/null; then
    service php7.1-fpm reload || Error 'PHP-FPM 7.1 reload failed, ACT NOW!'
elif hash php-fpm7.2 2> /dev/null; then
    service php7.2-fpm reload || Error 'PHP-FPM 7.2 reload failed, ACT NOW!'
fi
service apache2 reload || Error 'Apache reload failed, ACT NOW!'

echo "OK."
