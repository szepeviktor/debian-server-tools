#!/bin/bash
#
# Use realpath cache despite open_basedir restriction.
#
# DEPENDS       :apt-get install php7.4-dev

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

printf '; priority=20\nextension=realpath_turbo.so\n' >/etc/php/7.4/mods-available/realpath_turbo.ini
phpenmod realpath_turbo

# Check extension
php --ri realpath_turbo
