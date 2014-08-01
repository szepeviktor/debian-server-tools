#!/bin/bash
#
# Download and extract latest phpMyAdmin from SF
#
# VERSION       :0.1
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# UPSTREAM      :https://sourceforge.net/projects/phpmyadmin/files/latest/download


FILERELEASES="https://sourceforge.net/api/file/index/project-id/23067/mtime/desc/limit/20/rss"

# get releases RSS
#   parse first release element
#   parse tarball URL
#   get tarball
wget -q -O- "$FILERELEASES" \
    | grep -m1 '<link>.*phpMyAdmin-[0-9.]\+-english.tar.xz' \
    | sed 's|<[^>]*>||g' \
    | wget -nv -N --content-disposition -i-

# latest tarball
TARBALL="$(ls phpMyAdmin-* | sort -n | tail -n 1)"

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
    -xf "$TARBALL" && echo "OK." || echo 'NOT ok!'

