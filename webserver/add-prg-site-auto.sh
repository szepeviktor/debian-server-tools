#!/bin/bash
#
# Add utility site.
#
# VERSION       :0.2.0
# DEPENDS       :apt-get install apache2 php5-cli php5-fpm php5-mysqlnd courier-mta apg netcat-openbsd git
# DEPENDS       :/usr/local/bin/composer
# DEPENDS       :/usr/local/sbin/apache-resolve-hostnames.sh
# DEPENDS       :/usr/local/sbin/webrestart.sh

# Usage
#
# Custom SSL certificate or Let’s Encrypt certificate
#
#     certbot certonly --verbose --text --manual --agree-tos --manual-public-ip-logging-ok --email EMAIL -d DOMAIN
#     editor /etc/ssl/private/CN-private.key
#     editor /etc/ssl/localcerts/CN-public.pem

set -e

# Check HTTP/auth credentials
HTTP_USER="$(Data get-value apt.apache2.prg-http-user "")"
[ -n "$HTTP_USER" ]
HTTP_PASSWORD="$(Data get-value apt.apache2.prg-http-pwd "")"
[ -n "$HTTP_PASSWORD" ]
SSL_CN="$(Data get-value apt.apache2.prg-ssl-cn "")"
[ -n "$SSL_CN" ]

# Check debian-server-tools
[ -f "package/phpmyadmin-get.sh" ]

# Apache user
getent passwd web &> /dev/null

U="prg$((RANDOM % 1000))"
DOMAIN="prg.$(ip addr show dev eth0|sed -ne 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p').xip.io"

# Create user
adduser --disabled-password --gecos "" ${U}

# Add webserver to this group
adduser web ${U}

# For bounce messages
echo "${U}@$(hostname -f): webmaster@$(hostname -d)" >> /etc/courier/aliases/system-user
makealiases

# Website directories
(
    cd /home/${U}/
    install -o ${U} -g ${U} -m 0550 -d website
    cd website/
    mkdir session tmp html backup pagespeed
    chmod 0555 html

    # HTTP authentication
    htpasswd -bBc ./htpasswords "$HTTP_USER" "$HTTP_PASSWORD"
    chmod 0640 ./htpasswords
)

# Document root
PRG_ROOT="/home/${U}/website/html"

# Favicon and robots.txt
wget -nv -nc -P ${PRG_ROOT} "https://www.debian.org/favicon.ico"
echo -e "User-agent: *\nDisallow: /\n# Please stop sending further requests." > ${PRG_ROOT}/robots.txt

# Default image
cp webserver/default-image-38FC48.jpg ${PRG_ROOT}/

# OPcache control panel
# kabel / ocp.php
cp webserver/ocp.php ${PRG_ROOT}/

# APC/APCu ontrol panel
# apc.php from APC trunk for PHP 5.4-
#     php -r 'if(1!==version_compare("5.5",phpversion())) exit(1);' \
#         && wget -nv -O${TOOLS_DOCUMENT_ROOT}/apc.php "http://git.php.net/?p=pecl/caching/apc.git;a=blob_plain;f=apc.php;hb=HEAD"
# apc.php from APCu master for PHP 5.5+
php -r 'if(1===version_compare("5.5",phpversion())) exit(1);' \
    && wget -nv -O ${PRG_ROOT}/apc.php "https://github.com/krakjoe/apcu/raw/master/apc.php"
echo "<?php define('ADMIN_USERNAME', '${HTTP_USER}');
      define('ADMIN_PASSWORD', '${HTTP_PASSWORD}');" > ${PRG_ROOT}/apc.conf.php
chmod 0640 ${PRG_ROOT}/apc.conf.php

# PHP info
wget -nv -O ${PRG_ROOT}/pif.php \
    https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/shared-hosting-aid/php-vars.php

# PHPMyAdmin
cp package/phpmyadmin-get.sh ${PRG_ROOT}/
(
    cd ${PRG_ROOT}/
    ./phpmyadmin-get.sh
    rm -f phpMyAdmin-*-english.tar.xz
    cd phpMyAdmin-*-english/
    cp config.sample.inc.php config.inc.php
    # http://docs.phpmyadmin.net/en/latest/config.html#basic-settings
    sed -i -e 's/^.*\$cfg\[.blowfish_secret.\].*$/\/\/ cfg-blowfish_secret/' config.inc.php
    sed -i -e "s|cfg-blowfish_secret|cfg-blowfish_secret\n\
\$cfg['blowfish_secret'] = '$(apg -n 1 -m 30)';\n\
\$cfg['MemoryLimit'] = '384M';\n\
\$cfg['DefaultLang'] = 'en';\n\
\$cfg['PmaNoRelation_DisableWarning'] = true;\n\
\$cfg['SuhosinDisableWarning'] = true;\n\
// \$cfg['CaptchaLoginPublicKey'] = '<Site key from https://www.google.com/recaptcha/admin >';\n\
// \$cfg['CaptchaLoginPrivateKey'] = '<Secret key>';\n|" config.inc.php
)

# PHP Secure Configuration Checker
(
    cd ${PRG_ROOT}/
    git clone https://github.com/sektioneins/pcc.git
)

# Redis control panel
if echo "ping" | nc -C -q 3 localhost 6379 | grep -F "+PONG"; then
    (
        cd ${PRG_ROOT}/
        composer create-project --no-interaction --stability=dev erik-dubbelboer/php-redis-admin radmin
        cd radmin/
        cp includes/config.sample.inc.php includes/config.inc.php
    )
fi

# Memcached control panel
if echo stats | nc -q 3 localhost 11211 | grep -F "bytes"; then
    (
        cd /home/${U}/website/
        mkdir phpMemAdmin
        cd phpMemAdmin/
        echo '{ "require": { "clickalicious/phpmemadmin": "~0.3" }, "scripts": { "post-install-cmd":
            [ "Clickalicious\\PhpMemAdmin\\Installer::postInstall" ] } }' > composer.json
        composer install || true
        yes "y" | composer install
        mv web memadmin
        mv ./app/.config.dist ./app/.config
        sed -i -e '0,/"username":.*/s//"username": null,/' ./app/.config
        sed -i -e '0,/"password":.*/s//"password": null,/' ./app/.config
    )
fi

# Set owner
chown -R ${U}:${U} /home/${U}/website

# Create PHP pool
(
    #cd /etc/php5/fpm/pool.d/
    cd /etc/php/7.0/fpm/pool.d/
    sed -e "s/@@USER@@/${U}/g" < ../Prg-pool.conf > ${U}.conf
    # PHP Secure Configuration Checker allowed IP address
    #     env[PCC_ALLOW_IP] = 1.2.3.*
)

# Create Apache site
(
    cd /etc/apache2/sites-available/
    sed -e "s/@@CN@@/${SSL_CN}/g" -e "s/@@PRG_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Prg-site.conf > ${DOMAIN}.conf
)

# Enable site
a2ensite ${DOMAIN}
webserver/apache-resolve-hostnames.sh

# Reload webserver
# We may not have the certificate in place
apache2ctl configtest && webserver/webrestart.sh
