#!/bin/bash

set -e -x

# PHP 5.6
apt-get install -y php5-cli php5-curl php5-fpm php5-gd \
    php5-mcrypt php5-mysqlnd php5-readline php5-dev \
    php5-sqlite php5-apcu php-pear

# System-wide strict values
PHP_TZ="Europe/Budapest"
sed -i 's/^expose_php\s*=.*$/expose_php = Off/' /etc/php5/fpm/php.ini
sed -i 's/^max_execution_time\s*=.*$/max_execution_time = 65/' /etc/php5/fpm/php.ini
sed -i 's/^memory_limit\s*=.*$/memory_limit = 384M/' /etc/php5/fpm/php.ini
sed -i 's/^post_max_size\s*=.*$/post_max_size = 4M/' /etc/php5/fpm/php.ini
sed -i 's/^upload_max_filesize\s*=.*$/upload_max_filesize = 4M/' /etc/php5/fpm/php.ini # FullHD JPEG
sed -i 's/^allow_url_fopen\s*=.*$/allow_url_fopen = Off/' /etc/php5/fpm/php.ini
sed -i "s|^;date.timezone\s*=.*\$|date.timezone = ${PHP_TZ}|" /etc/php5/fpm/php.ini
sed -i "s|^;mail.add_x_header\s*=.*\$|mail.add_x_header = Off|" /etc/php5/fpm/php.ini
# OPcache - only "prg" site is allowed
sed -i 's|^;opcache.restrict_api\s*=.*$|opcache.restrict_api = /home/web/website/|' /etc/php5/fpm/php.ini
sed -i 's/^;opcache.memory_consumption\s*=.*$/opcache.memory_consumption = 256/' /etc/php5/fpm/php.ini
sed -i 's/^;opcache.interned_strings_buffer\s*=.*$/opcache.interned_strings_buffer = 16/' /etc/php5/fpm/php.ini
# There may be more than 10k files
#     find /home/ -type f -name "*.php" | wc -l
sed -i 's/^;opcache.max_accelerated_files\s*=.*$/opcache.max_accelerated_files = 10000/' /etc/php5/fpm/php.ini
# APCu
echo -e "\n[apc]\napc.enabled = 1\napc.shm_size = 64M" >> /etc/php5/fpm/php.ini

# Pool-specific values go to pool configs

# @TODO Measure: realpath_cache_size = 16k  realpath_cache_ttl = 120
#       https://www.scalingphpbook.com/best-zend-opcache-settings-tuning-config/

grep -Ev "^\s*#|^\s*;|^\s*$" /etc/php5/fpm/php.ini | pager
# Disable "www" pool
#sed -i 's/^/;/' /etc/php5/fpm/pool.d/www.conf
mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.default
cp -v ${D}/webserver/phpfpm-pools/* /etc/php5/fpm/
# PHP 5.6+ session cleaning
mkdir -p /usr/local/lib/php5
cp -v ${D}/webserver/sessionclean5.5 /usr/local/lib/php5/
# PHP 5.6+
echo -e "15 *\t* * *\troot\t[ -x /usr/local/lib/php5/sessionclean5.5 ] && /usr/local/lib/php5/sessionclean5.5" \
    > /etc/cron.d/php5-user

# @FIXME PHP timeouts
# - PHP max_execution_time
# - PHP max_input_time
# - Apache ProxyTimeout
# - FastCGI -idle-timeout
# - PHP-FPM pool request_terminate_timeout

# Suhosin extension
#     https://github.com/stefanesser/suhosin/releases
apt-get install -y php5-suhosin-extension
php5enmod -s fpm suhosin
# Disable for PHP-CLI
#     php5dismod -s cli suhosin
#     phpdismod -v ALL -s cli suhosin
# Disable suhosin
#     [suhosin]
#     suhosin.simulation = On
# Check priority
ls -l /etc/php5/fpm/conf.d/20-suhosin.ini

# @TODO Package realpath_turbo
# https://github.com/Whissi/realpath_turbo
# https://github.com/Mikk3lRo/realpath_turbo PHP7.0

# PHP file modification time protection
# https://ioncube24.com/signup

# @TODO .ini-handler, Search for it!

# PHP security directives
#     mail.add_x_header
#     assert.active
#     suhosin.executor.disable_emodifier = On
#     suhosin.disable.display_errors = 1
#     suhosin.session.cryptkey = $(apg -m 32)

# PHP directives for Drupal
#     suhosin.get.max_array_index_length = 128
#     suhosin.post.max_array_index_length = 128
#     suhosin.request.max_array_index_length = 128

# No FPM pools -> no restart

# ionCube Loader
# https://www.ioncube.com/loaders.php
#     zend_extension = ioncube_loader_lin_5.6.so
#     ic24.enable = Off
