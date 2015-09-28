#!/bin/bash --version

exit 0

# PHP-NG

# http://repos.zend.com/zend-server/early-access/php7/
apt-get install -y build-essential autoconf pkg-config re2c bison \
    libxml2-dev libssl-dev libbz2-1.0 libbz2-dev libcurl4-openssl-dev libjpeg-dev \
    libpng-dev libxpm-dev libfreetype6-dev libgmp3-dev libmcrypt-dev \
    libmysqlclient-dev librecode-dev libreadline-dev
# Hack.
ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h

# Get source
wget --content-disposition https://github.com/php/php-src/archive/master.zip
unzip php-src-master.zip && cd php-src-master/

# Build
./buildconf
#@TODO: sort options w,w/o,enable
./configure --prefix=/opt/phpng --with-config-file-path=/opt/phpng/etc \
    --enable-fpm \
    --enable-mbstring \
    --enable-zip \
    --enable-bcmath \
    --enable-pcntl \
    --enable-ftp \
    --enable-exif \
    --enable-calendar \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-wddx \
    --enable-gd-native-ttf \
    --enable-gd-jis-conv \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-pdo-sqlite \
    --with-curl \
    --with-mcrypt \
    --with-iconv \
    --with-gmp \
    --with-gd \
    --with-jpeg-dir=/usr \
    --with-png-dir=/usr \
    --with-zlib-dir=/usr
    --with-xpm-dir=/usr \
    --with-freetype-dir=/usr \
    --with-openssl \
    --with-gettext=/usr \
    --with-zlib=/usr \
    --with-bz2=/usr \
    --with-recode=/usr \
    --without-t1lib
make
#make test
make install

# Init script https://packages.debian.org/source/jessie/php5
wget http://security.debian.org/debian-security/pool/updates/main/p/php5/php5_5.6.9+dfsg-0+deb8u1.debian.tar.xz
unzip php5_*.debian.tar.xz
cp debian/php5-fpm.init /etc/init.d/php-fpm
editor /etc/init.d/php-fpm
update-rc.d php-fpm defaults
#NAME=
#DAEMON=
#DAEMON_ARGS=
#CONF_PIDFILE=
#
#do_check()
#    /usr/lib/php5/php5-fpm-checkconf || return 1
service php-fpm start

# nghttp2
apt-get install -y make binutils autoconf  automake autotools-dev libtool pkg-config \
    zlib1g-dev libcunit1-dev libssl-dev libxml2-dev libev-dev libevent-dev \
    libjansson-dev libjemalloc-dev
spdylay....
git-release ....
