#!/bin/bash

# Apache add new site.
# Not a script but a manual.

exit 0

read -p "user name: " U
read -p "domain name: (without WWW) " DOMAIN

adduser --disabled-password --gecos "" ${U}

# Add system mail alias to direct bounces to one address
# E.g. VIRTUAL-USERGROUP could be one client
#     USER@HOSTNAME:   VIRTUAL-USERGROUP@HOSTNAME
# Set forwarding address on the smarthost
#     echo "RECIPIENT@DOMAIN.COM" > .courier-VIRTUAL-USERGROUP

editor /etc/courier/aliases/system-user
makealiases

# Add sudo permissions for real users to become this user
cd /etc/sudoers.d/

# Optionally set up SSH key for logging in
sudo -u ${U} -i -- ssh-keygen -t rsa
cd /home/${U}/.ssh/
cp -a id_rsa.pub authorized_keys2
zip --encrypt ${U}.zip id_rsa*

# Website directories
cd /home/${U}/ && mkdir -v website && cd website
mkdir -v {session,tmp,html,pagespeed,backup,fastcgicache}

# HTTP authentication
read -p "HTTP/auth user: " HTTP_USER
htpasswd -c ./htpasswords ${HTTP_USER}
chmod 600 ./htpasswords

# Install WordPress
cd /home/${U}/

# Migrate files **NOW**
#
# HTML-ize WordPress
#     https://gist.github.com/szepeviktor/4535c5f20572b77f1f52

# Repair permissions, line ends
find -type f "(" -name ".htaccess" -o -name "*.php" -o -name "*.js" -o -name "*.css" ")" -exec dos2unix --keepdate "{}" ";"
find -type f -exec chmod --changes 644 "{}" ";"
find -type d -exec chmod --changes 755 "{}" ";"
chmod -v 750 website*
find -name wp-config.php -exec chmod -v 400 "{}" ";"
find -name settings.php -exec chmod -v 400 "{}" ";"
find -name .htaccess -exec chmod -v 640 "{}" ";"

# Set owner
chown -cR ${U}:${U} *

# WordPress wp-config.php
# https://api.wordpress.org/secret-key/1.1/salt/
# WordPress fail2ban

# Migrate database NOW!

# Create WordPress database from wp-config
# See: ${D}/mysql/wp-createdb.sh
# See: ${D}/mysql/alter-table.sql

# wp-cli configuration
# path, url, debug, user, skip-plugins
editor wp-cli.yml

# Check core files
uwp core verify-checksums

# Add your WP user
uwp user create viktor viktor@szepe.net --role=administrator --user_pass=<PASSWORD> --display_name=v

# Clean up old data
uwp transient delete-all
uwp w3-total-cache flush
uwp search-replace --precise --recurse-objects --all-tables-with-prefix --dry-run /oldhome/path /home/path

# PHP
cd /etc/php5/fpm/pool.d/
sed "s/@@USER@@/$U/g" < ../Skeleton-pool.conf > $U.conf

# Apache
# CloudFlase, Incapsula
#     a2enmod remoteip
cd /etc/apache2/sites-available
# Non-SSL
sed -e "s/@@SITE_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Skeleton-site.conf > ${DOMAIN}.conf
# SSL
# Name main SSL site (non-SNI) "001-${DOMAIN}.conf"
# See: webserver/Apache-SSL.md
sed -e "s/@@SITE_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Skeleton-site-ssl.conf > ${DOMAIN}.conf
# In case of "www." set ServerAlias
editor ${DOMAIN}.conf
# Enable site
a2ensite ${DOMAIN}
apache-resolve-hostnames.sh

# Restart webserver + PHP
# See: ${D}/webserver/webrestart.sh

# Logrotate
editor /etc/logrotate.d/apache2-${DOMAIN}
# Prerotate & postrotate

# Add cron jobs
cd /etc/cron.d/
# See: ${D}/webserver/preload-cache.sh
