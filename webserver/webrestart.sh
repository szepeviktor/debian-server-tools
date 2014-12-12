#!/bin/bash
#
# Restart PHP-FPM and Apache dependently
#
# VERSION       :0.1
# DATE          :2014-12-12
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/webrestart.sh
# DEPENDS       :apt-get install php5-fpm apache2

error() {
    echo "ERROR: $1"
    exit 1
}

php5-fpm -t || error "php-fpm config"
echo ----
apache2ctl configtest || error "apache config"
echo ----

service php5-fpm restart || error "php-fpm restart !!!"
service apache2 reload || error "apache restart !!!"

echo "Webserver restart OK."
