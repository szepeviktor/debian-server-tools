#!/bin/bash
#
# Apache add new site.
#
# Not a script but a manual.

exit 0

# Domain and DNS checks
#
# See /monitoring/domain-expiry.sh
# See /monitoring/dns-watch.sh

read -r -e -p "user name: " U
read -r -e -p "domain name without WWW: " DOMAIN

adduser --disabled-password --gecos "" ${U}

# Add webserver to this group
adduser _web ${U}

# Add system mail alias to deliver bounces to one address
# E.g. VIRTUAL-USERGROUP could be one client
#     USER@HOSTNAME:       VIRTUAL-USERGROUP@HOSTNAME
#     wordpress@HOSTNAME:  VIRTUAL-USERGROUP@HOSTNAME
# Set forwarding address on the smarthost
#     echo "RECIPIENT@DOMAIN.COM" > .courier-VIRTUAL-USERGROUP
echo "${U}@$(hostname -f): webmaster@$(hostname -d)" >> /etc/courier/aliases/system-user
makealiases

# * Install SSH key
S="$(getent passwd "$U"|cut -d: -f6)/.ssh";mkdir --mode 0700 "$S";touch "${S}/authorized_keys2";chown -R ${U}:${U} "$S"
editor "${S}/authorized_keys2"
# * Git URL
echo "ssh://${U}@${DOMAIN}:SSH-PORT/home/${U}/dev.git"

# Website directories
mkdir -v --mode=0750 /home/${U}/website
mkdir -v /home/${U}/website/{session,tmp,html,pagespeed,backup,fastcgicache}
chmod 0555 /home/${U}/website/html

# Install WordPress
cd /home/${U}/website/html/

# Migrate files **NOW**
#
# HTML-ize WordPress
#     https://gist.github.com/szepeviktor/4535c5f20572b77f1f52

# Repair permissions, line ends
find -type f "(" -name ".htaccess" -o -name "*.php" -o -name "*.js" -o -name "*.css" ")" -exec dos2unix --keepdate "{}" ";"
find -type f -exec chmod --changes 0644 "{}" ";"
find -mindepth 1 -type d -exec chmod --changes 0755 "{}" ";"
find -name wp-config.php -exec chmod -v 0400 "{}" ";"
#find -name settings.php -exec chmod -v 0400 "{}" ";"
find -name .htaccess -exec chmod -v 0640 "{}" ";"

# Set owner
chown -cR ${U}:${U} /home/${U}/

# WordPress wp-config.php skeleton
#     define( 'ABSPATH', dirname( __FILE__ ) . '/html/' );

# Wordpress Fail2ban

# Migrate database NOW!
# Create WordPress database from wp-config
# See /mysql/wp-createdb.sh
# See /mysql/alter-table.sql

# wp-cli configuration
# path, url, debug, user, skip-plugins
editor wp-cli.yml

# Check core files
uwp core verify-checksums

# Add your WP user
uwp user create viktor viktor@szepe.net --role=administrator --display_name=v --user_pass=<PASSWORD>

# Clean up old data
uwp transient delete-all
uwp w3-total-cache flush
uwp search-replace --precise --recurse-objects --all-tables-with-prefix --dry-run /oldhome/path /home/path

# * Mount wp-content/cache on tmpfs
#     editor /etc/fstab
#     tmpfs  /home/${U}/website/html/static/cache  tmpfs  user,noauto,rw,relatime,uid=$(id -u "$U"),gid=$(id -g "$U"),mode=0755  0 0
wp-lib.sh --root="/home/${U}/website/html/static/cache/" mount 100

# PHP pool
#cd /etc/php5/fpm/pool.d/
cd /etc/php/7.0/fpm/pool.d/
sed "s/@@USER@@/${U}/g" < ../Skeleton-pool.conf > ${U}.conf
editor ${U}.conf

# SSL certificate
read -e -p "Common Name: " -i "$DOMAIN" CN
editor /etc/ssl/localcerts/${CN}-public.pem
editor /etc/ssl/private/${CN}-private.key
#cat /etc/letsencrypt/live/${CN}/privkey.pem > /etc/ssl/private/${CN}-private.key
#cat /etc/letsencrypt/live/${CN}/cert.pem /etc/letsencrypt/live/${CN}/chain.pem > /etc/ssl/localcerts/${CN}-public.pem
#nice openssl dhparam 2048 >> /etc/ssl/localcerts/${CN}-public.pem

# Apache vhost
# CloudFlase, Incapsula, StackPath
#a2enmod remoteip
cd /etc/apache2/sites-available/
# SSL
# "001-${DOMAIN}.conf" non-SNI site
# See /webserver/Apache-SSL.md
sed -e "s/@@SITE_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Skeleton-site-ssl.conf > ${DOMAIN}.conf
# OCSP server monitoring
( cd ..; ./install.sh monitoring/ocsp-check.sh
editor /etc/cron.hourly/ocsp-check-${DOMAIN}.sh
chmod +x /etc/cron.hourly/ocsp-check-*.sh )
# Certificate's common name differs from domain name
#sed -e "s/@@CN@@/${CN}/g" -e "s/@@SITE_USER@@/${U}/g" < Skeleton-site-ssl.conf > ${DOMAIN}.conf
# * Non-SSL
sed -e "s/@@SITE_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Skeleton-site.conf > ${DOMAIN}.conf

# Include the HPKP header: backup key, "Public-Key-Pins-Report-Only:" "Public-Key-Pins:"
# See https://developer.mozilla.org/en-US/docs/Web/Security/Public_Key_Pinning
# See https://developers.google.com/web/updates/2015/09/HPKP-reporting-with-chrome-46
openssl x509 -in /etc/ssl/localcerts/${CN}-public.pem -noout -pubkey \
 | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64 -A

# Subresource integrity <link href="" integrity="sha384-SHA384_HASH" crossorigin="anonymous">
# https://www.srihash.org/
openssl dgst -sha384 -binary | openssl enc -base64 -A

# In case of "www." set ServerAlias
editor ${DOMAIN}.conf
# Enable site
a2ensite ${DOMAIN}
apache-resolve-hostnames.sh

# Restart webserver + PHP
# See /webserver/webrestart.sh
webrestart.sh

# * Logrotate for log in $HOME
editor /etc/logrotate.d/apache2-${DOMAIN}
# Prerotate & postrotate

# Add to fail2ban
fail2ban-client set apache-combined addlogpath /var/log/apache2/${U}-ssl-error.log
fail2ban-client set apache-instant addlogpath /var/log/apache2/${U}-ssl-error.log
# * Non-SSL
fail2ban-client set apache-combined addlogpath /var/log/apache2/${U}-error.log
fail2ban-client set apache-instant addlogpath /var/log/apache2/${U}-error.log

# Add cron jobs
# Mute cron errors
#     php -r 'var_dump(E_ALL ^ E_NOTICE ^ E_WARNING ^ E_DEPRECATED ^ E_STRICT);' -> int(22517)
#     https://maximivanov.github.io/php-error-reporting-calculator/
#     /usr/bin/php -d error_reporting=22517 -d disable_functions=error_reporting -f cron.php
# Cron log
#     job | ts "\%d \%b \%Y \%T \%z" >> CRON-LOG
cd /etc/cron.d/
# See /webserver/preload-cache.sh

# Contact form notification email
# Authenticated send to foreign mailboxes
editor /etc/courier/esmtproutes
#     website.tld:smarthost.foreign.com,587 /SECURITY=REQUIRED
#     #website.tld:smarthost.foreign.com,465 /SECURITY=SMTPS
editor /etc/courier/esmtpauthclient
#     smarthost.foreign.com,587 username password
#     #smarthost.foreign.com,465 username password

# Monit
# See /monitoring/monit/services/.website

# Goaccess
# See /webserver/goaccess.sh
