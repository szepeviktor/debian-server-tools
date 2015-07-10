#!/bin/bash
#
# Download and extract latest multilanguage phpMyAdmin from GitHub.
#
# VERSION       :0.1.1
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/phpmyadmin-get.sh
# SOURCE        :https://github.com/phpmyadmin/phpmyadmin

# FIXME Could always use this URL: https://github.com/phpmyadmin/phpmyadmin/archive/STABLE.zip
# FIXME Include only English language

TAGS_API="https://api.github.com/repos/phpmyadmin/phpmyadmin/tags"

# Tags API JSON response
#     first non-beta-alpha release
#     tarball URL
if ! wget -q -O- "$TAGS_API" \
    | grep -m1 -A6 '"name":\s*"RELEASE_[0-9_]\+"' \
    | grep -m1 '"tarball_url":' | cut -d'"' -f4 \
    | wget -nv --content-disposition -i-; then

    echo "Download error $?" >&2
    exit 1
fi

# Latest tarball
TARBALL="$(ls phpmyadmin-phpmyadmin-*tar* | sort -n | tail -n 1)"

if [ -z "$TARBALL" ]; then
    echo "No tarball found." >&2
    exit 2
fi

# Extract
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
    --exclude=PMAStandard \
    --exclude=po \
    --exclude=scripts \
    --exclude=test \
    --exclude=README.rst \
    --exclude=.gitignore \
    --exclude=.jshintrc \
    --exclude=.travis.yml \
    --exclude=build.xml \
    -xf "$TARBALL" && echo "OK." || echo 'NOT ok!'
