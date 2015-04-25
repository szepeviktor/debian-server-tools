#!/bin/bash
#
# Download and extract latest phpMyAdmin 4.0 from SF
# Older version compatible with PHP 5.2 and MySQL 5. Supported for security fixes only, until Jan 1, 2017.
#
# VERSION       :0.2
# DATE          :2015-04-23
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/phpmyadmin-get-old-sf.sh
# SOURCE        :https://sourceforge.net/projects/phpmyadmin/files/latest/download


# needs higher limit to include 4.0.x
FILERELEASES="http://sourceforge.net/projects/phpmyadmin/rss?limit=200"

# releases RSS / first english-only release element / tarball URL
wget -q -O- "$FILERELEASES" \
    | grep -m1 '<link>.*phpMyAdmin-4\.0\.[0-9.]\+-english.tar.xz' \
    | sed 's|<[^>]*>||g' \
    | wget -nv -N --content-disposition -i-

# latest tarball
TARBALL="$(ls phpMyAdmin-*tar* | sort -n | tail -n 1)"

# extract
tar --exclude=doc \
    --exclude=.scrutinizer.yml \
    --exclude=.coveralls.yml \
    --exclude=setup \
    --exclude=examples \
    --exclude=ChangeLog \
    --exclude=composer.json \
    --exclude=CONTRIBUTING.md \
    --exclude=DCO \
    --exclude=LICENSE \
    --exclude=phpunit.xml.hhvm \
    --exclude=phpunit.xml.nocoverage \
    --exclude=README \
    --exclude=RELEASE-DATE-* \
    -xf "$TARBALL" && echo "OK." || echo 'NOT ok!'
