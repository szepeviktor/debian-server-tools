#!/bin/bash

set -e -x

# Redis, in-memory object cache
apt-get install -y redis-server

# PHP 5 extension from PECL
if [ "$(dpkg-query --showformat="\${Status}" --show php5-cli 2> /dev/null)" == "install ok installed" ]; then
    pecl install redis
    echo -e "; priority=20\nextension=redis.so" > /etc/php5/mods-available/redis.ini
    php5enmod redis
fi

if [ "$(dpkg-query --showformat="\${Status}" --show php7.0-cli 2> /dev/null)" == "install ok installed" ]; then
    # Is php7.0-redis available?
    if [ -n "$(aptitude --disable-columns --display-format "%p" search "?exact-name(php7.0-redis)")" ]; then #"
        # PHP 7 extension from dotdeb
        apt-get install -y php7.0-redis
    else
        # PHP 7 extension from source
        apt-get install -y php7.0-dev re2c
        git clone https://github.com/phpredis/phpredis.git
        (
            cd phpredis/
            git checkout php7
            phpize7.0
            # igbinary disables inc() and dec()
            #./configure --enable-redis-igbinary
            ./configure
            make
            make install
        )
        chmod -x /usr/lib/php/20151012/redis.so
        echo -e "; priority=20\nextension=redis.so" > /etc/php/7.0/mods-available/redis.ini
        phpenmod -v 7.0 -s ALL redis

        # Run test
        php tests/TestRedis.php --class Redis
    fi
fi

# Check extension
php -m | grep -Fx "redis"

# Check server
echo "FLUSHALL" | nc -C -q 10 localhost 6379
