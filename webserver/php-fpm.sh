#!/bin/bash
#
# DOCS          :https://salsa.debian.org/php-team/php/blob/master-7.2/debian/changelog

Php_pager()
{
    if [ "$DISABLE_PHP_PAGER" == True ]; then
        cat
    else
        pager
    fi
}

# shellcheck disable=SC1091
source debian-setup-functions.inc.sh

set -e -x

test -n "$PHP"

PHP_FPM_DIR="/etc/php/${PHP}/fpm"
PHP_FPM_INI="${PHP_FPM_DIR}/php.ini"
PHP_TZ="UTC"
CWD="$(dirname "${BASH_SOURCE[0]}")"

# Later versions of Ondřej Surý's PHP-FPM "Depends: systemd | systemd-tmpfiles"
# CVE-2017-18925
Getpkg opentmpfiles sid
# @nonDebian
Pkg_install_quiet systemd-tmpfiles

# @nonDebian
Pkg_install_quiet "php${PHP}-fpm" libpcre3 \
    "php${PHP}-curl" "php${PHP}-gd" "php${PHP}-intl" "php${PHP}-mysql" \
    "php${PHP}-sqlite3"
# Not compiled in every PHP binary: mbstring, xml
if [ -n "$(apt-cache madison "php${PHP}-mbstring" 2>/dev/null)" ]; then
    Pkg_install_quiet "php${PHP}-mbstring"
fi
if [ -n "$(apt-cache madison "php${PHP}-xml" 2>/dev/null)" ]; then
    Pkg_install_quiet "php${PHP}-xml"
fi

# Shim directory for PHP 5.6
if dpkg --compare-versions "$PHP" lt 7.0 && [ ! -d /etc/php ]; then
    mkdir /etc/php
    ln -s ../php5 "/etc/php/${PHP}"
fi

# FPM configuration
sed -e 's/^;process_control_timeout\s*=.*$/process_control_timeout = 30s/' -i "${PHP_FPM_DIR}/php-fpm.conf"

# php.ini for FPM
sed -e 's/^user_ini.filename\s*=\s*$/user_ini.filename =/' -i "$PHP_FPM_INI"
sed -e 's/^expose_php\s*=.*$/expose_php = Off/' -i "$PHP_FPM_INI"
sed -e 's/^max_execution_time=.*$/max_execution_time = 65/' -i "$PHP_FPM_INI"
sed -e 's/^memory_limit\s*=.*$/memory_limit = 128M/' -i "$PHP_FPM_INI"
sed -e 's/^post_max_size\s*=.*$/post_max_size = 4M/' -i "$PHP_FPM_INI"
# FullHD JPEG
#     rawtoppm 1920 1080 < /dev/urandom > random-fullhd.ppm
#     convert random-fullhd.ppm -quality 94 random-fullhd.jpg
sed -e 's/^upload_max_filesize\s*=.*$/upload_max_filesize = 4M/' -i "$PHP_FPM_INI"
sed -e 's/^allow_url_fopen\s*=.*$/allow_url_fopen = Off/' -i "$PHP_FPM_INI"
sed -e "s|^;date.timezone\\s*=.*\$|date.timezone = ${PHP_TZ}|" -i "$PHP_FPM_INI"
sed -e 's|^;mail.add_x_header\s*=.*$|mail.add_x_header = Off|' -i "$PHP_FPM_INI"
# Only Prg site is allowed
sed -e 's/^;opcache.memory_consumption\s*=.*$/opcache.memory_consumption = 256/' -i "$PHP_FPM_INI"
sed -e 's/^;opcache.interned_strings_buffer\s*=.*$/opcache.interned_strings_buffer = 16/' -i "$PHP_FPM_INI"
# TODO Set opcache.restrict_api

# OPcache - There may be more than 2k files
#     find /home/ -type f -name "*.php" | wc -l
sed -e 's/^;opcache.max_accelerated_files\s*=.*$/opcache.max_accelerated_files = 10000/' -i "$PHP_FPM_INI"

# APCu
printf '\n[apc]\napc.enabled = 1\napc.shm_size = 64M\n' >>"$PHP_FPM_INI"

# TODO Measure: realpath_cache_size = 16k
#               realpath_cache_ttl = 120
# https://www.scalingphpbook.com/best-zend-opcache-settings-tuning-config/

# Display PHP directives
DISABLE_PHP_PAGER="$(Data get-value auto-check-system "False")"
grep -E -v '^\s*(#|;|$)' "$PHP_FPM_INI" | Php_pager
# Disable "www" pool
mv "${PHP_FPM_DIR}/pool.d/www.conf" "${PHP_FPM_DIR}/pool.d/www.conf.default"
# Add skeletons
cp "${CWD}/phpfpm-pools/"* "${PHP_FPM_DIR}/"
# PHP 5.6 session cleaning
if dpkg --compare-versions "$PHP" lt 7.0; then
    mkdir -p /usr/local/lib/php5
    cp "${CWD}/sessionclean5.5" /usr/local/lib/php5/
    printf '15 *  * * *  root\t/usr/local/lib/php5/sessionclean5.5\n' >/etc/cron.d/php-sessionclean
fi

# FIXME PHP timeouts
# - PHP max_execution_time
# - PHP max_input_time
# - FastCGI -idle-timeout
# - PHP-FPM pool request_terminate_timeout

# Suhosin extension
# Note: To disable
#     [suhosin]
#     suhosin.simulation = On
if Data get-values package.apt.sources "" | grep -q -F -x 'suhosin'; then
    if dpkg --compare-versions "$PHP" lt 7.0; then
        # https://github.com/stefanesser/suhosin/releases
        Pkg_install_quiet php5-suhosin-extension
        php5enmod -s fpm suhosin
        # Disable for PHP-CLI
        if hash phpdismod 2>/dev/null; then
            phpdismod -v ALL -s cli suhosin
        else
            php5dismod -s cli suhosin
        fi
        # Check priority
        if ! grep -q '^; priority=' "/etc/php/${PHP}/mods-available/suhosin.ini"; then
            # Fix symlink name
            if hash phpdismod 2>/dev/null; then
                phpdismod -v ALL -s fpm suhosin
                sed -e 's/^extension=.*$/; priority=70\n&/' -i "/etc/php/${PHP}/mods-available/suhosin.ini"
                phpenmod -v ALL -s fpm suhosin
            else
                php5dismod -s fpm suhosin
                sed -e 's/^extension=.*$/; priority=70\n&/' -i "/etc/php/${PHP}/mods-available/suhosin.ini"
                php5enmod -s fpm suhosin
            fi
        fi
    else
        # TODO Suhosin extension for PHP 7.x
        echo "Not yet released https://github.com/sektioneins/suhosin7/releases"
    fi
fi

# Use realpath cache despite open_basedir restriction
# https://github.com/Whissi/realpath_turbo
#Pkg_install_quiet php-realpath-turbo

# PHP security directives
#     suhosin.executor.disable_emodifier = On
#     suhosin.disable.display_errors = 1
#     suhosin.session.cryptkey = $(apg -m 32)

# PHP directives for Drupal
#     suhosin.get.max_array_index_length = 128
#     suhosin.post.max_array_index_length = 128
#     suhosin.request.max_array_index_length = 128

# PHP file modification time protection
# https://ioncube24.com/signup

# ionCube Loader
#     https://www.ioncube.com/loaders.php
#     zend_extension = ioncube_loader_lin_7.0.so
#     ic24.enable = Off

# Siteprotection
Dinstall monitoring/siteprotection.sh
