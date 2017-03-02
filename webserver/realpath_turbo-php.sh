#!/bin/bash
#
# Use realpath cache despite open_basedir restriction.
#
# DEPENDS5      :apt-get install php5-dev
# DEPENDS       :apt-get install php7.0-dev

set -e -x

wget -qO- https://github.com/Whissi/realpath_turbo/archive/master.tar.gz | tar -xz

(
    cd realpath_turbo-master/
    phpize
    ./configure
    make
    make test NO_INTERACTION=1; echo $?
    make "INSTALL=$(pwd)/build/shtool install -c --mode=0644" install
)

# PHP 5.*
#echo -e "; priority=20\nextension=realpath_turbo.so" > /etc/php5/mods-available/realpath_turbo.ini
#php5enmod realpath_turbo

echo -e "; priority=20\nextension=realpath_turbo.so" > /etc/php/7.0/mods-available/realpath_turbo.ini
phpenmod realpath_turbo

# Check extension
php --ri realpath_turbo
