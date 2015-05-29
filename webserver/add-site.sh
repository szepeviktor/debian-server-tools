#!/bin/bash

# Apache add new site.
# Not a script but a manual.

exit 0


U=<USER>
DOMAIN=<DOMAIN>

adduser --disabled-password $U

# add system mail alias for <USER>
cd /etc/courier/aliases
makealiases

# add sudo permissions for real users
cd /etc/sudoers.d/
# set up SSH key
sudo -u $U -i -- ssh-keygen -t rsa
cd /home/$U/.ssh
cp -a id_rsa.pub authorized_keys2
zip --encrypt $U.zip id_rsa*

cd /home/$U/
mkdir website && cd website
mkdir {session,tmp,html,pagespeed,backup}

# HTTP authentication
htpasswd -c ./htpasswords <HTTP-USER>
chmod 600 ./htpasswords

# existing WP install
cd /home/$U/

# migrate files NOW
# HTML-ize WordPress  https://gist.github.com/szepeviktor/4535c5f20572b77f1f52

# repair permissions, line ends
find -type f \( -name ".htaccess" -o -name "*.php" -o -name "*.js" -o -name "*.css" \) -exec dos2unix --keepdate \{\} \;
chown -R $U:$U *
find -type f -exec chmod --changes 644 \{\} \;
find -type d -exec chmod --changes 755 \{\} \;
chmod -v 750 public_*
find -name wp-config.php -exec chmod -v 400 \{\} \;
find -name settings.php -exec chmod -v 400 \{\} \;
find -name .htaccess -exec chmod -v 640 \{\} \;

# WordPress wp-config.php
# https://api.wordpress.org/secret-key/1.1/salt/
# WordPress fail2ban

# migrate database NOW

# create WordPress database from wp-config, see: mysql/wp-createdb.sh

# set wp-cli url, debug, user, skip-plugins
editor wp-cli.yml

# add own WP user
uwp user create viktor viktor@szepe.net --role=administrator --user_pass=<PASSWORD> --display_name=v

# clean up old data
uwp transient delete-all
uwp w3-total-cache flush
uwp search-replace --dry-run --precise /oldhome/path /home/path

# PHP
cd /etc/php5/fpm/pool.d/
sed "s/@@USER@@/$U/g" < ../Skeleton-pool.conf > $U.conf
# purge old sessions
editor /etc/cron.d/php5-user
# minutes from 15-
# PHP -5.5
# 15 *	* * *	$U	[ -d /home/$U/public_html/session ] && /usr/lib/php5/sessionclean /home/$U/public_html/session $(/usr/lib/php5/maxlifetime)
#
# PHP 5.6+
# 15 *	* * *	root	[ -x /usr/local/lib/php5/sessionclean5.5 ] && /usr/local/lib/php5/sessionclean5.5

# Apache
cd /etc/apache2/sites-available
sed -e "s/@@SITE_DOMAIN@@/$DDOMAIN/g" -e "s/@@SITE_USER@@/$U/g" < Skeleton-site.conf > ${DOMAIN}.conf
# SSL see: webserver/Apache-SSL.md
sed -e "s/@@SITE_DOMAIN@@/$DOMAIN/g" -e "s/@@SITE_USER@@/$U/g" < Skeleton-site-ssl.conf > ${DOMAIN}.conf
# Development
sed -e "s/@@REVERSE_HIDDEN@@/$DOMAIN/g" -e "s/@@SITE_USER@@/$U/g" < Skeleton-site-ssl.conf > ${DOMAIN}.conf
# on "www..." set ServerAlias
editor ${DOMAIN}.conf
a2ensite $DOMAIN
# see: webrestart.sh
# logrotate
editor /etc/logrotate.d/apache2-${DOMAIN}
# prerotate & postrotate

# add cron jobs
cd /etc/cron.d/
# webserver/preload-cache.sh
