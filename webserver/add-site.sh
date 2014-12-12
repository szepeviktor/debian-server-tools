#!/bin/bash

# Apache add new site.
# Not a script but a manual.

exit 0


U=<USER>

adduser --disabled-password $U

# add system mail alias for <USER>
cd /etc/courier/aliases
makealiases

# add sudo permissions for real users
cd /etc/sudoers.d/

cd /home/$U/
mkdir public_html && cd public_html
mkdir {session,tmp,server,pagespeed,backup}

# HTTP authentication
htpasswd -c ./htpasswords <LOGIN>
chmod 600 ./htpasswords

# existing WP install
cd /home/$U/

# migrate files NOW

find -type f \( -name "*.php" -o -name "*.js" -o -name "*.css" \) -exec dos2unix --keepdate \{\} \;
chown -R $U:$U *
find -type f -exec chmod --changes 664 \{\} \;
find -type d -exec chmod --changes 775 \{\} \;
chmod -v 750 public_*
find -name wp-config.php -exec chmod -v 640 \{\} \;
find -name .htaccess -exec chmod -v 640 \{\} \;

# WordPress wp-config.php
# WordPress fail2ban

# migrate database NOW

# create WordPress database from wp-config, see: mysql/wp-createdb.sh

# add own user
sudo -u $U -- wp --path=$PWD user create viktor viktor@szepe.net --role=administrator --user_pass=<PASSWORD> --display_name=v

# PHP
cd /etc/php5/fpm/pool.d/
sed "s/@@USER@@/$U/g" < ../Skeleton.conf > $U.conf
# Apache
cd /etc/apache2/sites-available
D=<DOMAIN>
sed -e "s/@@DOMAIN@@/$D/g" -e "s/@@USER@@/$U/g" < Skeleton.conf > $D.conf
a2ensite $D
# see: webrestart.sh

# add cron job
cd /etc/cron.d/
