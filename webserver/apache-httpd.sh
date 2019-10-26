#!/bin/bash

set -e -x

# shellcheck disable=SC1091
source debian-setup-functions.inc.sh

# TODO Apache-SSL move out ssl.conf to a file
# Consider libapache2-mod-qos (testing backport)
# Apache security
# - https://github.com/rfxn/linux-malware-detect
# - https://github.com/Neohapsis/NeoPI

CWD="$(dirname "${BASH_SOURCE[0]}")"

#apt-get install -y openssl apache2 apache2-utils
# Install-Recommends=false prevents installing: ssl-cert
Pkg_install_quiet --no-install-recommends apache2
# Path to certificates
mkdir /etc/ssl/localcerts

#     rotate 90
# Already "daily"
sed -i -e 's/\brotate 14$/rotate 90/' /etc/logrotate.d/apache2

# Run as "_web" user
adduser --disabled-password --no-create-home --gecos "" --force-badname _web
sed -e 's/^export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=_web/' -i /etc/apache2/envvars
sed -e 's/^export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=_web/' -i /etc/apache2/envvars

# Log 404-s also
sed -e 's/^LogLevel warn/LogLevel info/' -i /etc/apache2/apache2.conf

# Remove Location section
sed -e '/<Location \/server-status>/,/<\/Location>/d' -i /etc/apache2/mods-available/status.conf
# Modules
a2enmod actions rewrite headers deflate expires proxy_fcgi http2
cp -f "${CWD}/apache-conf-available/ssl-mozilla-intermediate.default" /etc/apache2/mods-available/ssl.conf
# ssl module depends on socache_shmcb
a2enmod ssl

# Configuration
# @TODO Add '<IfModule !module.c> Error "We need that module"' to confs and sites.
cp -f "${CWD}/apache-conf-available/"*.conf /etc/apache2/conf-available/
cp -f "${CWD}/apache-sites-available/"*.conf /etc/apache2/sites-available/
# Security through obscurity
sed -e 's/^ServerTokens OS/ServerTokens Prod/' -i /etc/apache2/conf-available/security.conf
# php-fpm.conf is not enabled, use settings per vhost
a2enconf logformats admin-address h5bp http2

# Unnecessary
a2dismod -f negotiation
a2disconf localized-error-pages

# robots.txt
printf 'User-agent: *\nDisallow: /\n# Please stop sending further requests.\n' >/var/www/html/robots.txt

# Log search
Dinstall monitoring/logsearch.sh

# Run as APACHE_RUN_* user and group
service apache2 restart
