#!/bin/bash
#
# Restart PHP-FPM and Apache dependently
#
# VERSION       :0.2.0
# DATE          :2015-08-16
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install php5-fpm apache2
# LOCATION      :/usr/local/sbin/webrestart.sh

Error() {
    echo "ERROR: $1" >&2
    exit 1
}

php5-fpm -t || Error "PHP-FPM configuration test"
echo "-----"

apache2ctl configtest || Error "Apache configuration test"
echo "-----"

service php5-fpm reload || Error 'PHP-FPM reload failed, ACT NOW!'

service apache2 reload || Error 'Apache reload failed, ACT NOW!'

echo "Webserver restart OK."
