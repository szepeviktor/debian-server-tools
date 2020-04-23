#!/bin/bash
#
# Add new Apache site.
#
# Not a script but a manual.

exit 0

# Domain and DNS checks
#
# See /monitoring/domain-expiry.sh
# See /monitoring/dns-watch.sh

read -r -e -p "User name: " U
read -r -e -p "Domain name without WWW: " DOMAIN

adduser --disabled-password --gecos "" "$U"

# Add webserver to this group
adduser _web "$U"

# Add system mail alias to deliver bounces to one address
# E.g. VIRTUAL-USERGROUP could be one client
#     USER@HOSTNAME:       VIRTUAL-USERGROUP@HOSTNAME
#     wordpress@HOSTNAME:  VIRTUAL-USERGROUP@HOSTNAME
# Set forwarding address on the smarthost
#     echo "RECIPIENT@DOMAIN.COM" >.courier-VIRTUAL-USERGROUP
echo "${U}@$(hostname -f): webmaster@$(hostname -d)" >>/etc/courier/aliases/system-user
makealiases

# * Install SSH key
S="$(getent passwd "$U"|cut -d: -f6)/.ssh";mkdir --mode 0700 "$S";touch "${S}/authorized_keys";chown -R "${U}:${U}" "$S"
editor "${S}/authorized_keys"
# * Git URL
echo "ssh://${U}@${DOMAIN}:SSH-PORT/home/${U}/dev.git"

# Website directories
mkdir -v --mode=0750 "/home/${U}/website"
#mkdir -v /home/${U}/website/{session,tmp,code,pagespeed,backup,fastcgicache}
mkdir -v "/home/${U}/website/"{session,tmp,code,pagespeed,backup}
chmod 0555 "/home/${U}/website/code"

# Add hosting.yml
cp -v /usr/local/src/debian-server-tools/webserver/hosting.yml "/home/${U}/website/"

# Install WordPress
# shellcheck disable=SC2164
cd "/home/${U}/website/code/"

# Migrate files NOW!
#
# See /webserver/WordPress.md
#
# * HTML-ize WordPress
#     https://gist.github.com/szepeviktor/4535c5f20572b77f1f52

# Find non-standard permissions, line ends
#grep -r -I -l $'\r'; grep -r -I -m 1 $'\r' | sed -e 's/\r/■/g'
find . -type f -not -perm 644; find . -type d -not -perm 755
# Repair permissions, line ends
#find . -type f "(" -name ".htaccess" -o -name "*.php" -o -name "*.js" -o -name "*.css" ")" -exec dos2unix --keepdate "{}" ";"
find . -type f -exec chmod --changes 0644 "{}" ";"
find . -mindepth 1 -type d -exec chmod --changes 0755 "{}" ";"
# Sensitive files
find . -name wp-config.php -exec chmod --verbose 0400 "{}" ";"
#find . -path "*/sites/*/settings.php" -exec chmod --verbose 0400 "{}" ";"
#find . -name .env -exec chmod --verbose 0400 "{}" ";"
find . -name .htaccess -exec chmod --verbose 0640 "{}" ";"
# Non-ASCII and non-Hungarian file names
find . -regextype posix-basic -regex '.*[^áÁéÉíÍóÓöÖőŐúÚüÜűŰ ./0-9@A-Z_a-z-].*'

# Set owner
chown -c -R "${U}:${U}" "/home/${U}/"

# wp-config.php skeleton

# WAF for WordPress

# Migrate database NOW!
#
# Create WordPress database from wp-config
# See /mysql/wp-createdb.sh
#     /usr/local/src/debian-server-tools/mysql/wp-createdb.sh
# See /mysql/alter-table.sql

# Check core files
u wp core verify-checksums

# Add your WP user
u wp user create viktor viktor@szepe.net --role=administrator --display_name=v --user_pass=PASSWORD

# wp-cli configuration
# path, url, debug, user, skip-plugins
editor wp-cli.yml

# Clean up old data
u wp transient delete-all
#u wp w3-total-cache flush
u wp search-replace --precise --recurse-objects --all-tables-with-prefix --dry-run /oldhome/path /home/path

# * Mount wp-content/cache on tmpfs
#     editor /etc/fstab
#     tmpfs  /home/${U}/website/code/static/cache  tmpfs  user,noauto,rw,relatime,uid=$(id -u $U),gid=$(id -g $U),mode=0755  0 0
wp-lib.sh --root="/home/${U}/website/code/static/cache/" mount 100

# * Default image
printf "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJ
TUUH4gMUEQE5VHnaPwAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAAnSURBVCjP
Y0xLS2PABoyNjbGKMzGQCEY1EANYcIX32bNnR0OJfhoA+8EE7eneRVUAAAAASUVORK5CYII=" | base64 -d >checkered-16x16.png

# PHP pool
# shellcheck disable=SC2164
#cd /etc/php5/fpm/pool.d/
# shellcheck disable=SC2164
cd /etc/php/7.2/fpm/pool.d/
sed "s/@@USER@@/${U}/g" <../Skeleton-pool.conf >"${U}.conf"
editor "${U}.conf"

# SSL certificate
# See /security/LetsEncrypt.md
read -r -e -p "Common Name: " -i "$DOMAIN" CN
editor "/etc/ssl/localcerts/${CN}-public.pem"
nice openssl dhparam 2048 >>"/etc/ssl/localcerts/${CN}-public.pem"
editor "/etc/ssl/private/${CN}-private.key"

# Apache vhost
# CloudFlase, Incapsula, StackPath
#a2enmod remoteip
# shellcheck disable=SC2164
cd /etc/apache2/sites-available/
# SSL
# "001-${DOMAIN}.conf" non-SNI site
# See /webserver/Apache-SSL.md
sed -e "s/@@SITE_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" <Skeleton-site-ssl.conf >"${DOMAIN}.conf"
# OCSP server monitoring
( cd /usr/local/src/debian-server-tools/ && ./install.sh monitoring/ocsp-check.sh
  editor "/usr/local/bin/ocsp--${DOMAIN}"
  chmod +x "/usr/local/bin/ocsp--${DOMAIN}"
  printf '05,35 *  * * *  nobody\t/usr/local/bin/ocsp--%s\n' "$DOMAIN" >"/etc/cron.d/ocsp-${DOMAIN//./-}" )
# Certificate's common name differs from domain name
#sed -e "s/@@CN@@/${CN}/g" -e "s/@@SITE_USER@@/${U}/g" <Skeleton-site-ssl.conf >"${DOMAIN}.conf"

# * HPKP (HTTP Public Key Pinning) including backup public key
#     Headers: Public-Key-Pins-Report-Only Public-Key-Pins
# See https://developer.mozilla.org/en-US/docs/Web/Security/Public_Key_Pinning
# See https://developers.google.com/web/updates/2015/09/HPKP-reporting-with-chrome-46
openssl x509 -in "/etc/ssl/localcerts/${CN}-public.pem" -noout -pubkey \
  | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64 -A

# * SRI (Subresource Integrity) for foreign CDN content
#     <link rel="stylesheet" href="URL" integrity="sha384-HASHBASE64" crossorigin="anonymous">
# See https://www.srihash.org/
openssl dgst -sha384 -binary | openssl enc -base64 -A

# CAA DNS record to pin certificate authorities
# See https://sslmate.com/labs/caa/

# In case of "www." set ServerAlias
# Set WORDPRESS_ROOT_URL and WORDPRESS_UPLOADS_URL
editor "${DOMAIN}.conf"
# Enable site
a2ensite "$DOMAIN"
apache-resolve-hostnames.sh

# Reload webserver and PHP
# See /webserver/webrestart.sh
webreload.sh

# Fail2ban
fail2ban-client set apache-combined addlogpath "/var/log/apache2/${U}-ssl-error.log"
fail2ban-client set apache-instant addlogpath "/var/log/apache2/${U}-ssl-error.log"
# * Non-SSL
fail2ban-client set apache-combined addlogpath "/var/log/apache2/${U}-error.log"
fail2ban-client set apache-instant addlogpath "/var/log/apache2/${U}-error.log"

# Cron jobs
# Mute cron errors
#     # php -r 'var_dump(E_ALL ^ E_NOTICE ^ E_WARNING ^ E_DEPRECATED ^ E_STRICT);' -> int(22517)
#     https://maximivanov.github.io/php-error-reporting-calculator/
#     /usr/bin/php7.2 -d error_reporting=22517 -d disable_functions=error_reporting -f /path/to/cron.php
# Cron log
#     cron-job-command | ts "\%d \%b \%Y \%T \%z" >>/path/to/cron.log
# shellcheck disable=SC2164
cd /etc/cron.d/
# /usr/local/bin/wp --quiet --path=/home/USER/website/code/project cron event run --due-now
# See /webserver/wp-install/wp-cron-cli.sh
# See /webserver/preload-cache.sh

# * Contact form notification email
# Authenticated send to foreign mailboxes
editor /etc/courier/esmtproutes
#     example.com:mail.hosting.tld,587 /SECURITY=REQUIRED
#     #example.com:mail.hosting.tld,465 /SECURITY=SMTPS
editor /etc/courier/esmtpauthclient
#     mail.hosting.tld,587 username password
#     #mail.hosting.tld,465 username password

# * Monit
# See /monitoring/monit/services/.website

# Git status check
# See /monitoring/tripwire-fake.sh

# Goaccess
# See /monitoring/goaccess.sh

# Document in hosting.yml
# See /webserver/hosting.yml

# * Install a Honey Pot
# https://www.projecthoneypot.org/faq.php#c

# * Development/Staging environment?
# domain name, SMTP, robots.txt

# Webmaster tools
echo "https://www.google.com/webmasters/tools/dashboard?siteUrl=https://${DOMAIN}/"
echo "https://www.bing.com/webmaster/home/addsite?from=mysites&addurl=https://${DOMAIN}/"
echo "https://webmaster.yandex.com/site/https:${DOMAIN}:443/access/"
