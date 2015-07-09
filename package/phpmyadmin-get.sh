#!/bin/bash
#
# Download and extract latest english-only phpMyAdmin.
#
# VERSION       :0.2.0
# DATE          :2015-07-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/phpmyadmin-get.sh

# Parse homepage
#HOMEPAGE_URL="https://www.phpmyadmin.net/downloads/"
#wget -qO- "$HOMEPAGE_URL" \
#    | grep -m1 -o 'href="https://files.phpmyadmin.net/phpMyAdmin/.*/phpMyAdmin-.*-english.tar.xz"' \
#    | cut -d'"' -f2 \
#    | wget -nv -N --content-disposition -i-

JSON_URL="https://www.phpmyadmin.net/home_page/version.json"

LATEST_VERSION="$(wget -q -O- "$JSON_URL"|sed -n '0,/^.*"version":\s*"\([^"]\+\)".*$/s//\1/p')" #'

wget -nv -N --content-disposition \
    "https://files.phpmyadmin.net/phpMyAdmin/${LATEST_VERSION}/phpMyAdmin-${LATEST_VERSION}-english.tar.xz"

# Freshest tarball in the current directory
TARBALL="$(ls -t phpMyAdmin-*-english.tar.xz | tail -n 1)"

# Extract tarball
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
