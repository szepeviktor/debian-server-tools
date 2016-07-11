#!/bin/bash
#
# Apache add prg site.
#
# Not a script but a manual.

exit 0

read -r -e -i "prg$((RANDOM % 1000))" -p "user name: " U
#read -e -i "prg.$(hostname -d)" -p "prg domain: " DOMAIN
read -e -i "prg.$(ip addr show dev eth0|sed -ne 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p').xip.io" -p "prg domain: " DOMAIN

adduser --disabled-password --gecos "" $U

# Add webserver to this group
adduser web ${U}

echo "${U}@$(hostname -f): webmaster@$(hostname -d)" >> /etc/courier/aliases/system-user
makealiases

# Website directories
cd /home/${U}/
mkdir website
chmod -v 750 website*
cd website/
mkdir {session,tmp,html,backup}

# HTTP authentication
read -e -p "prg HTTP/auth user: " HTTP_USER
read -e -s -p "prg HTTP/auth password: " HTTP_PASSWORD
htpasswd -bBc ./htpasswords "$HTTP_USER" "$HTTP_PASSWORD"
chmod -c 640 ./htpasswords

# Control panel for OPcache and APC
PRG_ROOT="/home/${U}/website/html"

# Favicon and robots.txt
wget -nv -P ${PRG_ROOT} "https://www.debian.org/favicon.ico"
echo -e "User-agent: *\nDisallow: /\n# Please stop sending further requests." > ${PRG_ROOT}/robots.txt

# Default image
cp -v ${D}/webserver/default-image-38FC48.jpg ${PRG_ROOT}/

# kabel / ocp.php
cp -v ${D}/webserver/ocp.php ${PRG_ROOT}

# apc.php from APC trunk for PHP 5.4-
#     php -r 'if(1!==version_compare("5.5",phpversion())) exit(1);' \
#         && wget -nv -O${TOOLS_DOCUMENT_ROOT}/apc.php "http://git.php.net/?p=pecl/caching/apc.git;a=blob_plain;f=apc.php;hb=HEAD"

# apc.php from APCu master for PHP 5.5+
php -r 'if(1===version_compare("5.5",phpversion())) exit(1);' \
    && wget -nv -O ${PRG_ROOT}/apc.php "https://github.com/krakjoe/apcu/raw/master/apc.php"
echo "<?php define('ADMIN_USERNAME', '${HTTP_USER}');
    define('ADMIN_PASSWORD', '${HTTP_PASSWORD}');" > ${PRG_ROOT}/apc.conf.php
chmod 640 ${PRG_ROOT}/apc.conf.php

# PHP info
wget -nv -O ${PRG_ROOT}/pif.php \
    https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/shared-hosting-aid/php-vars.php

# PHPMyAdmin
cd /home/${U}/website/html/
${D}/package/phpmyadmin-get.sh
cd phpMyAdmin-*-english/
cp -v config.sample.inc.php config.inc.php
apg -n 1 -m 30
#     http://docs.phpmyadmin.net/en/latest/config.html#basic-settings
editor config.inc.php
#     $cfg['MemoryLimit'] = '384M';
#     $cfg['blowfish_secret'] = '$(apg -n 1 -m 30)';
#     $cfg['DefaultLang'] = 'en';
#     $cfg['PmaNoRelation_DisableWarning'] = true;
#     $cfg['SuhosinDisableWarning'] = true;
#     $cfg['CaptchaLoginPublicKey'] = '<Site key from https://www.google.com/recaptcha/admin >';
#     $cfg['CaptchaLoginPrivateKey'] = '<Secret key>';
cd ../

# PHP Secure Configuration Checker
git clone https://github.com/sektioneins/pcc.git

# Redis admin
composer create-project --no-interaction --stability=dev erik-dubbelboer/php-redis-admin radmin
cd radmin/
cp -v includes/config.sample.inc.php includes/config.inc.php

# Set owner
chown -cR ${U}:${U} cd /home/${U}/

# PHP pool
cd /etc/php5/fpm/pool.d/
#cd /etc/php/7.0/fpm/pool.d/
sed "s/@@USER@@/${U}/g" < ../Prg-pool.conf > ${U}.conf
# PHP Secure Configuration Checker allow IP address
editor ${U}.conf
#     env[PCC_ALLOW_IP] = 1.2.3.*

# SSL certificate
read -e -p "Common Name: " CN
editor /etc/ssl/private/${CN}-private.key
editor /etc/ssl/localcerts/${CN}-public.pem

# Apache site
cd /etc/apache2/sites-available/
sed -e "s/@@PRG_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Prg-site.conf > ${DOMAIN}.conf
# Certificate's common name differs from domain name
#sed -e "s/@@CN@@/${CN}/g" -e "s/@@PRG_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Prg-site.conf > ${DOMAIN}.conf
# Consider Let’s Encrypt SSL certificate

# Enable site
a2ensite ${DOMAIN}
${D}/webserver/apache-resolve-hostnames.sh

# Restart services
${D}/webserver/webrestart.sh
