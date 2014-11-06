#!/bin/bash
#
# Download and extract latest phpMyAdmin from GitHub
#
# VERSION       :0.1
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/phpmyadmin-get.sh
# SOURCE        :https://github.com/phpmyadmin/phpmyadmin


# Older version compatible with PHP 5.2 and MySQL 5
#wget 'https://github.com/phpmyadmin/phpmyadmin/archive/RELEASE_4_0_10_4.tar.gz'

TAGSAPI="https://api.github.com/repos/phpmyadmin/phpmyadmin/tags"

# get Tags API JSON
#   parse first non-beta/alpha release
#   parse tarball URL
#   get tarball
wget -q -O- "$TAGSAPI" \
    | grep -m1 -A6 '"name": "RELEASE_[0-9_]\+",' \
    | grep -m1 '"tarball_url":' | cut -d'"' -f4 \
    | wget -v --content-disposition -i-

#FIXME  could always use this URL: https://github.com/phpmyadmin/phpmyadmin/archive/STABLE.zip

# latest tarball
TARBALL="$(ls phpmyadmin-phpmyadmin-* | sort -n | tail -n 1)"

# extract
tar --exclude=doc \
    --exclude=.coveralls.yml \
    --exclude=examples \
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

#$cfg['blowfish_secret']
# pwgen 7

#$cfg['SuhosinDisableWarning'] = true;
#$cfg['PmaNoRelation_DisableWarning'] = true;
#$cfg['DefaultLang'] = 'en';
#$cfg['ThemeDefault'] = 'original';
