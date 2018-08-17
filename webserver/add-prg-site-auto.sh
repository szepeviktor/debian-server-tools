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
# Put SSL certificate in place
#
#     editor /etc/ssl/private/CN-private.key
#     editor /etc/ssl/localcerts/CN-public.pem

set -e

test -n "$PHP"

# Check HTTP/auth credentials
HTTP_USER="$(Data get-value package.apache2.prg-http-user "")"
test -n "$HTTP_USER"
HTTP_PASSWORD="$(Data get-value package.apache2.prg-http-pwd "")"
test -n "$HTTP_PASSWORD"
# Check SSL certificate file name
SSL_CN="$(Data get-value package.apache2.prg-ssl-cn "")"
test -n "$SSL_CN"

# Check debian-server-tools
test -f "package/phpmyadmin-get.sh"

# Apache user exists
getent passwd _web &> /dev/null

U="prg$((RANDOM % 1000))"
DOMAIN="prg.$(ip addr show dev eth0|sed -ne 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p').xip.io"

# Create user
adduser --disabled-password --gecos "" ${U}

# Add webserver to this group
adduser _web ${U}

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
PRG_ROOT="/home/${U}/website/code"

# Favicon and robots.txt
wget -nv -nc -P ${PRG_ROOT} "https://www.debian.org/favicon.ico"
printf 'User-agent: *\nDisallow: /\n# Please stop sending further requests.\n' > ${PRG_ROOT}/robots.txt

# Default image
cp webserver/default-image-38FC48.jpg "${PRG_ROOT}/"

# OPcache control panel
# kabel / ocp.php
cp webserver/ocp.php "${PRG_ROOT}/"

# APCu ontrol panel
# apc.php from APCu master
php -r 'if(1===version_compare("5.5",phpversion())) exit(1);' \
    && wget -nv -O ${PRG_ROOT}/apc.php "https://github.com/krakjoe/apcu/raw/master/apc.php"
echo "<?php define('ADMIN_USERNAME', '${HTTP_USER}');
      define('ADMIN_PASSWORD', '${HTTP_PASSWORD}');" > "${PRG_ROOT}/apc.conf.php"
chmod 0640 "${PRG_ROOT}/apc.conf.php"

# PHP info
wget -nv -O "${PRG_ROOT}/pif.php" \
    https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/shared-hosting-aid/php-vars.php

# PHPMyAdmin
cp package/phpmyadmin-get.sh "${PRG_ROOT}/"
(
    cd "${PRG_ROOT}/"
    ./phpmyadmin-get.sh
    rm -f phpMyAdmin-*-english.tar.xz
    cd phpMyAdmin-*-english/
    cp config.sample.inc.php ../config.inc.php
    ln -sf ../config.inc.php .
    # http://docs.phpmyadmin.net/en/latest/config.html#basic-settings
    # shellcheck disable=SC2016
    sed -e 's|^.*\$cfg\[.blowfish_secret.\].*$|// cfg-blowfish_secret|' -i ../config.inc.php
    sed -e "s|cfg-blowfish_secret|cfg-blowfish_secret\\n\
\$cfg['blowfish_secret'] = '$(apg -n 1 -m 33)';\\n\
\$cfg['MemoryLimit'] = '384M';\\n\
\$cfg['DefaultLang'] = 'en';\\n\
\$cfg['PmaNoRelation_DisableWarning'] = true;\\n\
\$cfg['SuhosinDisableWarning'] = true;\\n\
// \$cfg['CaptchaLoginPublicKey'] = '<Site key from https://www.google.com/recaptcha/admin >';\\n\
// \$cfg['CaptchaLoginPrivateKey'] = '<Secret key>';\\n|" -i ../config.inc.php
)

# PHP Secure Configuration Checker
(
    cd "${PRG_ROOT}/"
    git clone https://github.com/sektioneins/pcc.git
)

# Redis control panel
if echo "ping" | nc -C -q 3 localhost 6379 | grep -F '+PONG'; then
    (
        cd "${PRG_ROOT}/"
        composer create-project --no-interaction --no-dev --stability=dev erik-dubbelboer/php-redis-admin radmin
        cd radmin/
        cp includes/config.sample.inc.php includes/config.inc.php
    )
fi

# Memcached control panel
if echo "stats" | nc -q 3 localhost 11211 | grep -F 'bytes'; then
    (
        cd "/home/${U}/website/"
        mkdir phpMemAdmin
        cd phpMemAdmin/
        echo '{ "require": { "clickalicious/phpmemadmin": "~0.3" }, "scripts": { "post-install-cmd":
            [ "Clickalicious\\PhpMemAdmin\\Installer::postInstall" ] } }' > composer.json
        composer install --no-dev || true
        yes "y" | composer install --no-dev
        mv web memadmin
        mv ./app/.config.dist ./app/.config
        sed -i -e '0,/"username":.*/s//"username": null,/' ./app/.config
        sed -i -e '0,/"password":.*/s//"password": null,/' ./app/.config
    )
fi

# Set owner
chown -R ${U}:${U} "/home/${U}/website"

# Create PHP pool
(
    cd "/etc/php/${PHP}/fpm/pool.d/"
    sed -e "s/@@USER@@/${U}/g" < ../Prg-pool.conf > ${U}.conf
    # PHP Secure Configuration Checker allowed IP address
    #     env[PCC_ALLOW_IP] = 1.2.3.*
)
sed -e "s|^;\\?opcache\\.restrict_api\\s*=.*\$|opcache.restrict_api = /home/${U}/website/|" -i "/etc/php/${PHP}/fpm/php.ini"

# Create Apache site
(
    cd /etc/apache2/sites-available/
    sed -e "s/@@CN@@/${SSL_CN}/g" -e "s/@@PRG_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Prg-site.conf > "${DOMAIN}.conf"
)

# Enable site
a2ensite "${DOMAIN}"
webserver/apache-resolve-hostnames.sh

# Reload webserver
# We may not have the certificate in place
if apache2ctl configtest; then
    webserver/webrestart.sh
else
    echo "Have prg certificate installed at /etc/ssl/localcerts/${SSL_CN}-public.pem and /etc/ssl/private/${SSL_CN}-private.key" 1>&2
fi
