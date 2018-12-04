#!/bin/bash
#
# Download and extract latest 4.0.x english-only phpMyAdmin from its homepage.
#
# VERSION       :0.1
# DATE          :2015-07-07
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/phpmyadmin-get-http.sh

HOMEPAGE_URL="https://www.phpmyadmin.net/downloads/"

if ! wget -q -O- "$HOMEPAGE_URL" \
    | grep -m 1 -o 'href="https://files.phpmyadmin.net/phpMyAdmin/4\.0..*/phpMyAdmin-4\.0\..*-english\.tar\.xz"' \
    | cut -d '"' -f 2 \
    | wget -nv -N --content-disposition -i-; then

    echo "Download error $?" 1>&2
    exit 1
fi

# Latest tarball
TARBALL="$(find . -type f -name "phpMyAdmin-*-english.tar.xz" -printf '%P\n' | sort -g | tail -n 1)"

if [ -z "$TARBALL" ]; then
    echo "No tarball found." 1>&2
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
