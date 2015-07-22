#!/bin/bash

# Apache add prg site.
# Not a script but a manual.

exit 0

U="web"
read -e -i "prg.$(hostname -d)" -p "prg domain: " DOMAIN

adduser --disabled-password --gecos "" $U

echo "${U}@$(hostname -d):   admin@$(hostname -d)" >> /etc/courier/aliases/system-user
makealiases

# Website directories
cd /home/${U}/
mkdir website
cd website
mkdir {session,tmp,html,pagespeed,backup,fastcgicache}

# HTTP authentication
read -p "prg HTTP/auth user: " HTTP_USER
htpasswd -c ./htpasswords HTTP_USER
chmod 600 ./htpasswords

# PHP
cd /etc/php5/fpm/pool.d/
sed "s/@@USER@@/${U}/g" < ../Dev-pool.conf > ${U}.conf

# Apache
cd /etc/apache2/sites-available
sed -e "s/@@PRG_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Dev-site.conf > ${DOMAIN}.conf
a2ensite ${DOMAIN}
${D}/webserver/apache-resolve-hostnames.sh

# Restart services
${D}/webserver/webrestart.sh
