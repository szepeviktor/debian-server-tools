#!/bin/bash
#
# Apache add new site.
#
# Not a script but a manual.

exit 0

# Domain and DNS checks
#
# See: ${D}/monitoring/domain-expiry.sh
# See: ${D}/monitoring/dns-watch.sh

read -r -p "user name: " U
read -r -p "domain name: (without WWW) " DOMAIN

adduser --disabled-password --gecos "" ${U}

# Add webserver to this group
adduser web ${U}

# Add system mail alias to direct bounces to one address
# E.g. VIRTUAL-USERGROUP could be one client
#     USER@HOSTNAME:       VIRTUAL-USERGROUP@HOSTNAME
#     wordpress@HOSTNAME:  VIRTUAL-USERGROUP@HOSTNAME
# Set forwarding address on the smarthost
#     echo "RECIPIENT@DOMAIN.COM" > .courier-VIRTUAL-USERGROUP

editor /etc/courier/aliases/system-user
makealiases

# * Add sudo permissions for real users to become this user
cd /etc/sudoers.d/

# * Allow SSH keys
S="/home/${U}/.ssh";mkdir --mode 700 "$S";touch "${S}/authorized_keys2";chown -R ${U}:${U} "$S"
editor "${S}/authorized_keys2"
# Git URL
echo "ssh://${U}@${DOMAIN}:SSH-PORT/home/${U}/dev.git"

# Website directories
mkdir -v --mode=750 /home/${U}/website
mkdir -v /home/${U}/website/{session,tmp,html,pagespeed,backup,fastcgicache}

# Install WordPress
cd /home/${U}/website/html/

# Migrate files **NOW**
#
# HTML-ize WordPress
#     https://gist.github.com/szepeviktor/4535c5f20572b77f1f52

# Repair permissions, line ends
find -type f "(" -name ".htaccess" -o -name "*.php" -o -name "*.js" -o -name "*.css" ")" -exec dos2unix --keepdate "{}" ";"
find -type f -exec chmod --changes 644 "{}" ";"
find -type d -exec chmod --changes 755 "{}" ";"
find -name wp-config.php -exec chmod -v 400 "{}" ";"
find -name settings.php -exec chmod -v 400 "{}" ";"
find -name .htaccess -exec chmod -v 640 "{}" ";"

# Set owner
chown -cR ${U}:${U} /home/${U}/

# WordPress wp-config.php skeleton
#     define( 'ABSPATH', dirname( __FILE__ ) . '/html/' );

# wordpress-fail2ban MU plugin

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

# * Mount wp-content/cache on tmpfs
#     editor /etc/fstab
#     tmpfs  /home/${U}/website/html/static/cache  tmpfs  user,noauto,rw,relatime,uid=$(id -u "$U"),gid=$(id -g "$U"),mode=0755  0 0
wp-lib.sh --root="/home/${U}/website/html/static/cache/" mount 100

# PHP
cd /etc/php5/fpm/pool.d/
sed "s/@@USER@@/${U}/g" < ../Skeleton-pool.conf > ${U}.conf
editor ${U}.conf

# Apache
# CloudFlase, Incapsula
#     a2enmod remoteip
cd /etc/apache2/sites-available
# Non-SSL
sed -e "s/@@SITE_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Skeleton-site.conf > ${DOMAIN}.conf
# * SSL
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
webrestart.sh

# * Logrotate for log in $HOME
editor /etc/logrotate.d/apache2-${DOMAIN}
# Prerotate & postrotate

# Add to fail2ban
fail2ban-client set apache-combined addlogpath /var/log/apache2/${U}-error.log
fail2ban-client set apache-instant addlogpath /var/log/apache2/${U}-error.log
# * SSL
fail2ban-client set apache-combined addlogpath /var/log/apache2/${U}-ssl-error.log
fail2ban-client set apache-instant addlogpath /var/log/apache2/${U}-ssl-error.log

# Add cron jobs
# Mute cron errors
#     php -r 'var_dump(E_ALL ^ E_NOTICE ^ E_WARNING ^ E_DEPRECATED ^ E_STRICT);' -> int(22517)
#     /usr/bin/php -d error_reporting=22517 -d disable_functions=error_reporting -f cron.php
cd /etc/cron.d/
# See: ${D}/webserver/preload-cache.sh
