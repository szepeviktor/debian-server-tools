#!/bin/bash

set -e -x

# Redis, in-memory cache
# @TODO move to stretch-backports
apt-get install -y redis-server

# @TODO Prevent shutdown during background saving
cat > /etc/sysctl.d/redis-overcommit.conf <<"EOF"
# https://redis.io/topics/faq#background-saving-fails-with-a-fork-error-under-linux-even-if-i-have-a-lot-of-free-ram
#vm.overcommit_memory = 1
EOF

# PHP 5 extension from PECL
if [ "$(dpkg-query --showformat="\${Status}" --show php5-cli 2> /dev/null)" == "install ok installed" ]; then
    pecl install redis
    echo -e "; priority=20\nextension=redis.so" > /etc/php5/mods-available/redis.ini
    php5enmod redis
fi

if [ "$(dpkg-query --showformat="\${Status}" --show php7.2-cli 2> /dev/null)" == "install ok installed" ]; then
    # Is php-redis available?
    if [ -n "$(aptitude --disable-columns --display-format "%p" search "?exact-name(php-redis)")" ]; then #"
        # PHP 7 extension
        apt-get install -y php-redis
    else
        # PHP 7 extension from source
        apt-get install -y php7.2-dev re2c
        git clone https://github.com/phpredis/phpredis.git
        (
            cd phpredis/
            git checkout php7
            phpize7.2
            # igbinary disables inc() and dec()
            #./configure --enable-redis-igbinary
            ./configure
            make
            make install
        )
        chmod -x /usr/lib/php/20170718/redis.so
        echo -e "; priority=20\nextension=redis.so" > /etc/php/7.2/mods-available/redis.ini
        phpenmod -v 7.2 -s ALL redis

        # Run test
        php tests/TestRedis.php --class Redis
    fi
fi

# Check extension
php --ri redis

# Check server
echo "FLUSHALL" | nc -C -q 3 localhost 6379
