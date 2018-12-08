#!/bin/bash
#
# Use realpath cache despite open_basedir restriction.
#
# DEPENDS5      :apt-get install php5-dev
# DEPENDS       :apt-get install php7.2-dev

set -e -x

wget -q -O- "https://github.com/Whissi/realpath_turbo/archive/master.tar.gz" | tar -xz

(
    cd realpath_turbo-master/
    phpize
    ./configure
    make
    make test NO_INTERACTION=1; echo "$?"
    make "INSTALL=$(pwd)/build/shtool install -c --mode=0644" install
)

# PHP 5.*
#printf '; priority=20\nextension=realpath_turbo.so\n' >/etc/php5/mods-available/realpath_turbo.ini
#php5enmod realpath_turbo

printf '; priority=20\nextension=realpath_turbo.so\n' >/etc/php/7.2/mods-available/realpath_turbo.ini
phpenmod realpath_turbo

# Check extension
php --ri realpath_turbo
