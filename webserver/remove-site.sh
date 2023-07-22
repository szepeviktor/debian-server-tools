#!/bin/bash

# Apache remove a site.
# Not a script but a manual.

# Archive
#
# - readme.txt: siteurl, docroot, email accounts
# - email aliases file, apache site config, PHP-FPM pool config
# - compress website files
# - dump and compress db
# - compress emails accounts
# - upload to long-term archive
#
# Remove
#
# - database
# - db user
# - website files
# - cron job
# - system user
# - apache site
# - PHP-FPM pool
# - email accounts
# - email aliases
# - email domain


exit 0


read -r -e -p "User name: " U
read -r -e -p "Domain name without WWW: " DOMAIN

# backup
tar -vcJf /root/$U_$(date "+%Y-%m-%d").tar.xz /home/$U
# backup PHP, Apache and logrotate configs, Apache logs

# remove user and user's home
del --remove-home $U

# revoke sudo permissions
cd /etc/sudoers.d/

# delete system mail alias
cd /etc/courier/aliases
makealiases
# also courier hosteddomains, esmtpacceptmailfor

# delete email accounts
cd /var/mail/

# drop database and database user
echo 'DROP DATABASE `<DB-NAME>`; DROP USER `<DB-USER>`@localhost;' | mysql

# remove PHP pool
rm /etc/php5/fpm/pool.d/$U.conf
# remove session cron
e /etc/cron.d/php5-user

# Apache config
a2dissite $D
rm /etc/apache2/sites-available/$D.conf
# see: webrestart.sh
# remove logrotate
rm /etc/logrotate.d/apache2-$D
# delete logs
rm /var/log/apache2/$U*.log*

# make fail2ban forget the log
fail2ban-client reload apache-combined

# remove cron jobs
cd /etc/cron.d/
