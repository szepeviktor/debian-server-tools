#!/bin/bash
#
# Add local utility site.
#
# VERSION       :0.1.0
# DEPENDS       :apt-get install apache2 php5-cli php5-fpm php5-mysqlnd courier-mta apg netcat-openbsd git
# DEPENDS       :/usr/local/bin/composer
# DEPENDS       :/usr/local/sbin/apache-resolve-hostnames.sh
# DEPENDS       :/usr/local/sbin/webrestart.sh

DOMAIN="prg.local"

set -e

# Check debian-server-tools
test -f "package/phpmyadmin-get.sh"

# Apache user must exists
getent passwd _web > /dev/null

U="prg$((RANDOM % 1000))"

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
)

# Document root
PRG_ROOT="/home/${U}/website/code"

# Favicon and robots.txt
wget -nv -nc -P ${PRG_ROOT} "https://www.debian.org/favicon.ico"
printf 'User-agent: *\nDisallow: /\n# Please stop sending further requests.\n' > ${PRG_ROOT}/robots.txt

# Default image
cp webserver/default-image-38FC48.jpg ${PRG_ROOT}/

# OPcache control panel
# kabel / ocp.php
cp webserver/ocp.php ${PRG_ROOT}/

# APC/APCu ontrol panel
# apc.php from APC trunk for PHP 5.4-
#     php -r 'if(1!==version_compare("5.5",phpversion())) exit(1);' \
#         && wget -nv -O${PRG_ROOT}/apc.php "http://git.php.net/?p=pecl/caching/apc.git;a=blob_plain;f=apc.php;hb=HEAD"
# apc.php from APCu master for PHP 5.5+
if php -r 'if (1 === version_compare("5.5", phpversion())) exit(1);'; then
    wget -nv -O ${PRG_ROOT}/apc.php "https://github.com/krakjoe/apcu/raw/master/apc.php"
    echo "<?php" > ${PRG_ROOT}/apc.conf.php
    chmod 0640 ${PRG_ROOT}/apc.conf.php
fi

# PHP info
wget -nv -O ${PRG_ROOT}/pif.php \
    "https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/shared-hosting-aid/php-vars.php"

# PHPMyAdmin
cp package/phpmyadmin-get.sh ${PRG_ROOT}/
(
    cd ${PRG_ROOT}/
    ./phpmyadmin-get.sh
    rm -f phpMyAdmin-*-english.tar.xz
    cd phpMyAdmin-*-english/
    cp config.sample.inc.php ../config.inc.php
    ln -sf ../config.inc.php .
    # http://docs.phpmyadmin.net/en/latest/config.html#basic-settings
    # shellcheck disable=SC2016
    sed -e 's/^.*\$cfg\[.blowfish_secret.\].*$/\/\/ cfg-blowfish_secret/' -i ../config.inc.php
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
    cd ${PRG_ROOT}/
    git clone "https://github.com/sektioneins/pcc.git"
)

# Redis control panel
if echo "ping" | nc -C -q 3 localhost 6379 | grep -F '+PONG'; then
    (
        cd ${PRG_ROOT}/
        composer create-project --no-interaction --no-dev --stability=dev erik-dubbelboer/php-redis-admin radmin
        cd radmin/
        cp includes/config.sample.inc.php includes/config.inc.php
    )
fi

# Memcached control panel
if echo "stats" | nc -q 3 localhost 11211 | grep -F 'bytes'; then
    (
        cd /home/${U}/website/
        mkdir phpMemAdmin
        cd phpMemAdmin/
        cat > composer.json <<"EOF"
{
  "repositories": [{ "type": "vcs", "url": "https://github.com/clickalicious/phpmemadmin.git" }],
  "require": { "clickalicious/phpmemadmin": "dev-master" },
  "scripts": { "post-autoload-dump": [ "Clickalicious\\PhpMemAdmin\\Installer::postInstall" ] }
}
EOF

        composer install --no-dev || true
        yes "y" | composer install --no-dev
        mv web memadmin
        mv ./app/.config.dist ./app/.config
        sed -e '0,/"username":.*/s//"username": null,/' -i ./app/.config
        sed -e '0,/"password":.*/s//"password": null,/' -i ./app/.config
    )
fi

# Set owner
chown -R ${U}:${U} /home/${U}/website

# Create PHP pool
(
    #cd /etc/php5/fpm/pool.d/
    cd /etc/php/7.2/fpm/pool.d/
    sed -e "s/@@USER@@/${U}/g" < ../Prg-pool.conf > ${U}.conf
    # PHP Secure Configuration Checker allowed IP address
    #     env[PCC_ALLOW_IP] = 1.2.3.*
)
#sed -e "s|^;\\?opcache.restrict_api\\s*=.*\$|opcache.restrict_api = /home/${U}/website/|" -i /etc/php5/fpm/php.ini
sed -e "s|^;\\?opcache.restrict_api\\s*=.*\$|opcache.restrict_api = /home/${U}/website/|" -i /etc/php/7.2/fpm/php.ini

# Create Apache site
(
    cd /etc/apache2/sites-available/
    sed -e "s|@@SITE_USER@@|${U}|g" < Prg-local-site.conf > "${DOMAIN}.conf"
)

# Enable site
a2ensite "${DOMAIN}"
webserver/apache-resolve-hostnames.sh

# Reload webserver
if apache2ctl configtest; then
    webserver/webrestart.sh
else
    echo "Configuration error for prg site" 1>&2
fi
