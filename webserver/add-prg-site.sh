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
read -e -p "prg HTTP/auth user: " HTTP_USER
read -e -p "prg HTTP/auth password? " HTTP_PASSWORD
htpasswd -bc ./htpasswords "$HTTP_USER" "$HTTP_PASSWORD"
chmod 640 ./htpasswords

# Control panel for opcache and APC
PRG_ROOT="/home/${U}/website/html"

# Favicon and robots.txt
wget -nv -P ${PRG_ROOT} "https://www.debian.org/favicon.ico"
echo -e "User-agent: *\nDisallow: /" > ${PRG_ROOT}/robots.txt

# Default image
cp -v ${D}/webserver/default-image-38FC48.jpg ${PRG_ROOT}/

# kabel / ocp.php
cp -v ${D}/webserver/ocp.php ${PRG_ROOT}

# apc.php from APC trunk for PHP 5.4-
#     php -r 'if(1!==version_compare("5.5",phpversion())) exit(1);' \
#         && wget -nv -O${TOOLS_DOCUMENT_ROOT}/apc.php "http://git.php.net/?p=pecl/caching/apc.git;a=blob_plain;f=apc.php;hb=HEAD"

# apc.php from APCu master for PHP 5.5+
php -r 'if(1===version_compare("5.5",phpversion())) exit(1);' \
    && wget -nv -O ${PRG_ROOT}/apc.php "https://github.com/krakjoe/apcu/raw/simplify/apc.php"
echo "<?php define('ADMIN_USERNAME','${HTTP_USER}');
    define('ADMIN_PASSWORD','${HTTP_PASSWORD}');" > ${PRG_ROOT}/apc.conf.php
chmod 640 ${PRG_ROOT}/apc.conf.php

# PHP info
cp -v $(dirname ${D})/wordpress-plugin-construction/shared-hosting-aid/php-vars.php ${PRG_ROOT}/pif.php
echo "<?php phpinfo();" > ${PRG_ROOT}/pif.php

# PHPMyAdmin
${D}/package/phpmyadmin-get.sh
cd phpMyAdmin-*-english
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

# PHP security check
git clone https://github.com/sektioneins/pcc.git
# Pool config
#     env[PCC_ALLOW_IP] = 1.2.3.*

# Set owner
chown -cR ${U}:${U} *

# PHP pool
cd /etc/php5/fpm/pool.d/
sed "s/@@USER@@/${U}/g" < ../Dev-pool.conf > ${U}.conf

# Apache site
cd /etc/apache2/sites-available
sed -e "s/@@PRG_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Prg-site.conf > ${DOMAIN}.conf
a2ensite ${DOMAIN}
${D}/webserver/apache-resolve-hostnames.sh

# Restart services
${D}/webserver/webrestart.sh
