#!/bin/bash
#
# Download and extract latest english-only phpMyAdmin.
#
# VERSION       :0.2.1
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

# Use DOAP file
#wget -qO- https://www.phpmyadmin.net/home_page/phpmyadmin-doap.xml \
#    | sed '0,/xmlns=/s//xmlns:doap=/' phpmyadmin-doap.xml \
#    | xmlstarlet sel -t -v '(/Project/release/Version/file-release[contains(@rdf:resource,"-english.tar.xz")]/@rdf:resource)[1]'
# Or by using `sed`
#wget -qO- https://www.phpmyadmin.net/home_page/phpmyadmin-doap.xml \
#    | sed -n '0,/^.*<file-release rdf:resource="\(\S\+-english\.tar\.xz\)" \/>.*$/s//\1/p'

JSON_URL="https://www.phpmyadmin.net/home_page/version.json"

LATEST_VERSION="$(wget -q -O- "$JSON_URL"|sed -n '0,/^.*"version":\s*"\([^"]\+\)".*$/s//\1/p')" #'

if ! wget -nv -N --content-disposition \
    "https://files.phpmyadmin.net/phpMyAdmin/${LATEST_VERSION}/phpMyAdmin-${LATEST_VERSION}-english.tar.xz"; then

    echo "Download error $?" >&2
    exit 1
fi

# Freshest tarball in the current directory
TARBALL="$(ls -t phpMyAdmin-*-english.tar.xz | tail -n 1)"

if [ -z "$TARBALL" ]; then
    echo "No tarball found." >&2
    exit 2
fi

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
