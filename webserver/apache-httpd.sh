#!/bin/bash

set -e -x

. debian-setup-functions

# TODO Apache-SSL move out ssl.conf to a file
# Consider libapache2-mod-qos (testing backport)
# Apache security
# - https://github.com/rfxn/linux-malware-detect
# - https://github.com/Neohapsis/NeoPI

apt-get install -y apache2 apache2-utils
# No snakeoil
apt-get purge -y ssl-cert

editor /etc/logrotate.d/apache2
#     daily
#     rotate 90

adduser --disabled-password --gecos "" web

editor /etc/apache2/envvars
#     export APACHE_RUN_USER=web
#     export APACHE_RUN_GROUP=web

a2enmod actions rewrite headers deflate expires proxy_fcgi

# Comment out '<Location /server-status>' block
editor /etc/apache2/mods-available/status.conf

a2enmod ssl
yes|cp -f webserver/apache-conf-available/*.conf /etc/apache2/conf-available/
yes|cp -f webserver/apache-sites-available/*.conf /etc/apache2/sites-available/

# Use php-fpm.conf settings per site
a2enconf h5bp

editor /etc/apache2/conf-enabled/security.conf
#     ServerTokens Prod

editor /etc/apache2/apache2.conf
#     LogLevel info

# robots.txt
echo -e "User-agent: *\nDisallow: /\n# Please stop sending further requests." > /var/www/html/robots.txt
