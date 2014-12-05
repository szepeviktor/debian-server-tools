#!/bin/bash
#
# Download and extract latest phpMyAdmin 4.0 from SF
# Older version compatible with PHP 5.2 and MySQL 5. Supported for security fixes only, until Jan 1, 2017.
#
# VERSION       :0.1
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/phpmyadmin-get-sf.sh
# SOURCE        :https://sourceforge.net/projects/phpmyadmin/files/latest/download


# Older version compatible with PHP 5.2 and MySQL 5
#wget 'http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/4.0.10.4/phpMyAdmin-4.0.10.4-english.tar.xz/download#!md5!b55c8f9c3447cd1faec3ae574e5daba2'

# needs more items to include 4.0.x
FILERELEASES="http://sourceforge.net/projects/phpmyadmin/rss?limit=100"

# get releases RSS
#   parse first release element
#   parse tarball URL
#   get tarball
wget -q -O- "$FILERELEASES" \
    | grep -m1 '<link>.*phpMyAdmin-4\.0\.[0-9.]\+-english.tar.xz' \
    | sed 's|<[^>]*>||g' \
    | wget -nv -N --content-disposition -i-

# latest tarball
TARBALL="$(ls phpMyAdmin-* | sort -n | tail -n 1)"

# extract
tar --exclude=doc \
    --exclude=.coveralls.yml \
    --exclude=setup \
    --exclude=ChangeLog \
    --exclude=composer.json \
    --exclude=CONTRIBUTING.md \
    --exclude=DCO \
    --exclude=LICENSE \
    --exclude=phpunit.xml.hhvm \
    --exclude=phpunit.xml.nocoverage \
    --exclude=README \
    -xf "$TARBALL" && echo "OK." || echo 'NOT ok!'

