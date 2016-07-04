#!/bin/bash
#
# Reload PHP FPM and Apache dependently.
#
# VERSION       :0.3.1
# DATE          :2015-12-21
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install php5-fpm apache2
# DEPENDS7      :apt-get install php7.0-fpm apache2
# LOCATION      :/usr/local/sbin/webrestart.sh

APACHE_GROUP="web"

Error() {
    echo "ERROR: $1" 1>&2
    exit 1
}

# PHP-PFM config test
php5-fpm -t || Error "PHP-FPM configuration test"
#/usr/sbin/php-fpm7.0 -t || Error "PHP-FPM configuration test"
echo "-----"

# Is Apache in this user's group?
APACHE_CONFIGS="$(ls /etc/apache2/sites-enabled/*.conf)"
while read -r CONFIG_FILE; do
    DOCROOT_MISSING="$(grep "^\s*<VirtualHost\|^\s*DocumentRoot" "$CONFIG_FILE" | sed -ne '/VirtualHost/n;/DocumentRoot/!p')"
    if [ -n "$DOCROOT_MISSING" ]; then
        Error "Missing DocumentRoot directive in ${CONFIG_FILE}"
    fi

    if [ -f /etc/apache2/mods-enabled/mpm_event.load ]; then
        SITE_USER="$(sed -ne '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "$CONFIG_FILE")"
        if [ -n "$SITE_USER" ]; then
            groups "$APACHE_GROUP" | grep -qw "$SITE_USER" || Error "Apache is not in ${SITE_USER} group"
        fi
    fi
done <<< "$APACHE_CONFIGS"

# Apache config test
apache2ctl configtest || Error "Apache configuration test"
echo "-----"

# Reload!
service php5-fpm reload || Error 'PHP-FPM reload failed, ACT NOW!'
#service php7.0-fpm reload || Error 'PHP-FPM reload failed, ACT NOW!'

service apache2 reload || Error 'Apache reload failed, ACT NOW!'

echo "Webserver reload OK."
