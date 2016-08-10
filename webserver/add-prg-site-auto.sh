#!/bin/bash
#
# Apache add prg site.
#

# Usage
#
# Custom SSL certificate or Let’s Encrypt certificate
#
# read -e -p "Common Name: " CN
# editor /etc/ssl/private/${CN}-private.key
# editor /etc/ssl/localcerts/${CN}-public.pem
#
# export CN
# export D=/usr/local/src/debian-server-tools/webserver
# HTTP_USER=user HTTP_PASSWORD=secret ./add-prg-site-auto.sh

set -e

# Check HTTP/auth credentials
[ -n "$HTTP_USER" ]
[ -n "$HTTP_PASSWORD" ]
[ -n "$CN" ]
[ -f "${D}/debian-setup.sh" ]

U="prg$((RANDOM % 1000))"
DOMAIN="prg.$(ip addr show dev eth0|sed -ne 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p').xip.io"

adduser --disabled-password --gecos "" $U

# Add webserver to this group
adduser web ${U}

# For bounce messages
echo "${U}@$(hostname -f): webmaster@$(hostname -d)" >> /etc/courier/aliases/system-user
makealiases

# Website directories
cd /home/${U}/
install -o ${U} -g ${U} -m 0750 -d website
cd website/
mkdir session tmp html backup pagespeed

# HTTP authentication
htpasswd -bBc ./htpasswords "$HTTP_USER" "$HTTP_PASSWORD"
chmod -c 0640 ./htpasswords

# Document root
PRG_ROOT="/home/${U}/website/html"

# Favicon and robots.txt
wget -nv -P ${PRG_ROOT} "https://www.debian.org/favicon.ico"
echo -e "User-agent: *\nDisallow: /\n# Please stop sending further requests." > ${PRG_ROOT}/robots.txt

# Default image
cp -v ${D}/webserver/default-image-38FC48.jpg ${PRG_ROOT}/

# OPcache control panel
# kabel / ocp.php
cp -v ${D}/webserver/ocp.php ${PRG_ROOT}/

# APC/APCu ontrol panel
# apc.php from APC trunk for PHP 5.4-
#     php -r 'if(1!==version_compare("5.5",phpversion())) exit(1);' \
#         && wget -nv -O${TOOLS_DOCUMENT_ROOT}/apc.php "http://git.php.net/?p=pecl/caching/apc.git;a=blob_plain;f=apc.php;hb=HEAD"
# apc.php from APCu master for PHP 5.5+
php -r 'if(1===version_compare("5.5",phpversion())) exit(1);' \
    && wget -nv -O ${PRG_ROOT}/apc.php "https://github.com/krakjoe/apcu/raw/master/apc.php"
echo "<?php define('ADMIN_USERNAME', '${HTTP_USER}');
      define('ADMIN_PASSWORD', '${HTTP_PASSWORD}');" > ${PRG_ROOT}/apc.conf.php
chmod -c 0640 ${PRG_ROOT}/apc.conf.php

# PHP info
wget -nv -O ${PRG_ROOT}/pif.php \
    https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/shared-hosting-aid/php-vars.php

# PHPMyAdmin
cd ${PRG_ROOT}/
${D}/webserver/package/phpmyadmin-get.sh
rm -f phpMyAdmin-*-english.tar.xz
cd phpMyAdmin-*-english/
cp -v config.sample.inc.php config.inc.php
#     http://docs.phpmyadmin.net/en/latest/config.html#basic-settings
sed -i -e 's/^.*\$cfg\[.blowfish_secret.\].*$/\/\/ cfg-blowfish_secret/' config.inc.php
sed -i -e "s|cfg-blowfish_secret|cfg-blowfish_secret\n\
\$cfg['blowfish_secret'] = '$(apg -n 1 -m 30)';\n\
\$cfg['MemoryLimit'] = '384M';\n\
\$cfg['DefaultLang'] = 'en';\n\
\$cfg['PmaNoRelation_DisableWarning'] = true;\n\
\$cfg['SuhosinDisableWarning'] = true;\n\
// \$cfg['CaptchaLoginPublicKey'] = '<Site key from https://www.google.com/recaptcha/admin >';\n\
// \$cfg['CaptchaLoginPrivateKey'] = '<Secret key>';\n|" config.inc.php

# PHP Secure Configuration Checker
cd ${PRG_ROOT}/
git clone https://github.com/sektioneins/pcc.git

# Redis control panel
if echo "ping" | nc -C -q 3 localhost 6379 | grep -F "+PONG"; then
    composer create-project --no-interaction --stability=dev erik-dubbelboer/php-redis-admin radmin
    cd radmin/
    cp -v includes/config.sample.inc.php includes/config.inc.php
fi

# Memcached control panel
if echo stats | nc -q 3 localhost 11211 | grep -F "bytes"; then
    cd /home/${U}/website/
    mkdir phpMemAdmin
    cd phpMemAdmin/
    echo '{ "require": { "clickalicious/phpmemadmin": "~0.3" }, "scripts": { "post-install-cmd":
        [ "Clickalicious\\PhpMemAdmin\\Installer::postInstall" ] } }' > composer.json
    composer install || true
    composer install
    mv web memadmin
    mv ./app/.config.dist ./app/.config
    sed -i -e '0,/"username":.*/s//"username": null,/' ./app/.config
    sed -i -e '0,/"password":.*/s//"password": null,/' ./app/.config
fi

# Set owner
chown -c -R ${U}:${U} /home/${U}/website

# Create PHP pool
cd /etc/php5/fpm/pool.d/
#cd /etc/php/7.0/fpm/pool.d/
sed "s/@@USER@@/${U}/g" < ../Prg-pool.conf > ${U}.conf
# PHP Secure Configuration Checker allowed IP address
#     env[PCC_ALLOW_IP] = 1.2.3.*

# Create Apache site
cd /etc/apache2/sites-available/
sed -e "s/@@CN@@/${CN}/g" -e "s/@@PRG_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Prg-site.conf > ${DOMAIN}.conf

# Enable site
a2ensite ${DOMAIN}
${D}/webserver/apache-resolve-hostnames.sh

# Reload services
${D}/webserver/webrestart.sh
