#!/bin/bash

set -e -x

PHP_TZ="Europe/Budapest"

# PHP 7.0
# @nonDebian
apt-get install -y php7.0-cli php7.0-fpm \
    php7.0-mbstring php7.0-json php7.0-intl \
    php7.0-readline php7.0-curl php7.0-gd php7.0-mysql \
    php7.0-xml php7.0-sqlite3 # Not for WP

sed -i 's/^user_ini.filename\s*=\s*$/user_ini.filename =/' /etc/php/7.0/fpm/php.ini
sed -i 's/^expose_php\s*=.*$/expose_php = Off/' /etc/php/7.0/fpm/php.ini
sed -i 's/^max_execution_time=.*$/max_execution_time = 65/' /etc/php/7.0/fpm/php.ini
sed -i 's/^memory_limit\s*=.*$/memory_limit = 128M/' /etc/php/7.0/fpm/php.ini
sed -i 's/^post_max_size\s*=.*$/post_max_size = 4M/' /etc/php/7.0/fpm/php.ini
# FullHD random image
#     rawtoppm 1920 1080 < /dev/urandom > random-fullhd.ppm
#     convert random-fullhd.ppm -quality 94 random-fullhd.jpg
sed -i 's/^upload_max_filesize\s*=.*$/upload_max_filesize = 4M/' /etc/php/7.0/fpm/php.ini # FullHD JPEG
sed -i 's/^allow_url_fopen\s*=.*$/allow_url_fopen = Off/' /etc/php/7.0/fpm/php.ini
sed -i "s|^;date.timezone\s*=.*\$|date.timezone = ${PHP_TZ}|" /etc/php/7.0/fpm/php.ini
sed -i "s|^;mail.add_x_header\s*=.*\$|mail.add_x_header = Off|" /etc/php/7.0/fpm/php.ini
# Only Prg site is allowed
sed -i 's/^;opcache.memory_consumption\s*=.*$/opcache.memory_consumption = 256/' /etc/php/7.0/fpm/php.ini
sed -i 's/^;opcache.interned_strings_buffer\s*=.*$/opcache.interned_strings_buffer = 16/' /etc/php/7.0/fpm/php.ini
# Set opcache.restrict_api

# OPcache - There may be more than 2k files
#     find /home/ -type f -name "*.php" | wc -l
sed -i 's/^;opcache.max_accelerated_files\s*=.*$/opcache.max_accelerated_files = 10000/' /etc/php/7.0/fpm/php.ini

# APCu
echo -e "\n[apc]\napc.enabled = 1\napc.shm_size = 64M" >> /etc/php/7.0/fpm/php.ini

# @TODO Measure: realpath_cache_size = 16k  realpath_cache_ttl = 120
#       https://www.scalingphpbook.com/best-zend-opcache-settings-tuning-config/

# Display PHP directives
grep -Ev "^\s*#|^\s*;|^\s*\$" /etc/php/7.0/fpm/php.ini | pager
# Disable "www" pool
mv /etc/php/7.0/fpm/pool.d/www.conf /etc/php/7.0/fpm/pool.d/www.conf.default
# Add skeletons
cp webserver/phpfpm-pools/* /etc/php/7.0/fpm/
# PHP session cleaning
#/usr/lib/php/sessionclean

# @FIXME PHP timeouts
# - PHP max_execution_time
# - PHP max_input_time
# - FastCGI -idle-timeout
# - PHP-FPM pool request_terminate_timeout

# Suhosin extension for PHP 7.0
#     https://github.com/stefanesser/suhosin7/releases

# PHP file modification time protection
# https://ioncube24.com/signup

# Use realpath cache despite open_basedir restriction
# https://github.com/Whissi/realpath_turbo

# @TODO .ini-handler, Search for it!

# PHP security directives
#     suhosin.executor.disable_emodifier = On
#     suhosin.disable.display_errors = 1
#     suhosin.session.cryptkey = $(apg -m 32)

# PHP directives for Drupal
#     suhosin.get.max_array_index_length = 128
#     suhosin.post.max_array_index_length = 128
#     suhosin.request.max_array_index_length = 128

# ionCube Loader
#     https://www.ioncube.com/loaders.php
#     zend_extension = ioncube_loader_lin_7.0.so
#     ic24.enable = Off

# @TODO /webserver/php-env-check.php
