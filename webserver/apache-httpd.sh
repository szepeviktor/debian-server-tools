#!/bin/bash

set -e -x

. debian-setup-functions

# TODO Apache-SSL move out ssl.conf to a file
# Consider libapache2-mod-qos (testing backport)
# Apache security
# - https://github.com/rfxn/linux-malware-detect
# - https://github.com/Neohapsis/NeoPI

#apt-get install -y openssl apache2 apache2-utils
# @nonDebian
apt-get install -y openssl/jessie-backports libssl1.0.0/jessie-backports \
    apache2 apache2-bin apache2-utils
# No snakeoil
apt-get purge -y ssl-cert
# Path to certificates
mkdir /etc/ssl/localcerts

#     rotate 90
# Already "daily"
sed -i -e 's|\brotate 14$|rotate 90|' /etc/logrotate.d/apache2

# Run as "_web" user
adduser --disabled-password --no-create-home --gecos "" --force-badname _web
sed -i -e 's|^export APACHE_RUN_USER=www-data|export APACHE_RUN_USER=_web|' /etc/apache2/envvars
sed -i -e 's|^export APACHE_RUN_GROUP=www-data|export APACHE_RUN_GROUP=_web|' /etc/apache2/envvars

# Modules
a2enmod actions rewrite headers deflate expires proxy_fcgi http2

# Remove Location section
sed -i -e '/<Location \/server-status>/,/<\/Location>/d' /etc/apache2/mods-available/status.conf

a2enmod ssl
yes | cp -f webserver/apache-conf-available/ssl-mozilla-intermediate.default /etc/apache2/mods-available/ssl.conf
# @TODO Add '<IfModule !module.c> Error "We need that module"' to confs and sites.
yes | cp -f webserver/apache-conf-available/*.conf /etc/apache2/conf-available/
yes | cp -f webserver/apache-sites-available/*.conf /etc/apache2/sites-available/

# php-fpm.conf is not enabled, use settings per vhost
a2enconf logformats admin-address h5bp http2

# Unnecessary
a2dismod -f negotiation
a2disconf localized-error-pages

# Security through obscurity
sed -i -e 's|^ServerTokens OS|ServerTokens Prod|' /etc/apache2/conf-available/security.conf
# Log 404-s also
sed -i -e 's|^LogLevel warn|LogLevel info|' /etc/apache2/apache2.conf

# robots.txt
echo -e "User-agent: *\nDisallow: /\n# Please stop sending further requests." > /var/www/html/robots.txt

# Log search
Dinstall monitoring/logsearch.sh
