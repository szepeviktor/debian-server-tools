#!/bin/bash

# Apache remove a site.
# Not a script but a manual.

exit 0


U=<USER>

# backup
tar -vcJf /root/$U_$(date "+%Y-%m-%d").tar.xz /home/$U
# backup PHP, Apache and logrotate configs, Apache logs

# remove user and user's home
del --remove-home $U

# delette system mail alias
cd /etc/courier/aliases
makealiases
# also courier hosteddomains, esmtpacceptmailfor

# revoke sudo permissions
cd /etc/sudoers.d/

# drop database and database user
echo 'DROP DATABASE `<DB_NAME>`; DROP USER `<DB_USER>`@localhost;' | mysql

# remove PHP pool
rm /etc/php5/fpm/pool.d/$U.conf
# remove session cron
e /etc/cron.d/php5-user

# Apache config
D=<DOMAIN>
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
