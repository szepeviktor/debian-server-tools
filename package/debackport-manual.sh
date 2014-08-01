#!/bin/bash
#
# Directs you to backport a Debian package.
# A fully manual version of debackport.sh
#
# VERSION       :0.1
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# UPSTREAM      :https://wiki.debian.org/SimpleBackportCreation


PKG="$1"
SUITE="jessie"
BPOREV="~bpo70+"
export DEBEMAIL="Viktor Szépe <viktor@szepe.net>"
# comment out SHORTBUILD to run debian/rules before building
SHORTBUILD="yes"
# upon "gpg: Can't check signature: public key not found" use --allow-unauthenticated
ALLOW_UNAUTH="--allow-unauthenticated"
# you may add special backport instructions
#SPECIAL_BACKPORT="yes"


# get Debian release
CURRENTSUITE="$(lsb_release --codename | cut -f2)"

# get package name from parent dir's name
[ -z "$PKG" ] && PKG="$(basename "$PWD")"
[ "$(uname -m)" = "x86_64" ] && ARCH="amd64" || ARCH="i386"
AVAILABLE="$(rmadison "$PKG" -a "$ARCH" -s "$SUITE")"
echo "rmadison: ${AVAILABLE}"

echo "Download sources:  dget --allow-unauthenticated -x DSCURL"
bash

echo "Find and Install missing build dependencies"
SOURCES="$(grep -m1 "^Source: " *.dsc | cut -d' ' -f2)"
if [ -z "$SOURCES" ] || [ "$(wc -l <<< "$SOURCES")" -gt 1 ]; then
    ls -1d */
    read -p "Please enter source package name: " SOURCES
fi
DIR="$(find -maxdepth 1 -type d -iname "${SOURCES}-*" | head -n 1)"

pushd "$DIR"

# check build dependencies
echo "dpkg-checkbuilddeps"
bash

echo "Indicate revision number"
dch --local "$BPOREV" --distribution "${CURRENTSUITE}-backports"

echo "Build binary packages:  dpkg-buildpackage -b -us -uc"
bash

popd

echo
echo "dpkg-sig -k 451A4FBA --sign builder *.deb"
echo "cd /var/www/mirror/server/debian"
echo "reprepro remove ${CURRENTSUITE} ${PKG}"
echo "reprepro includedeb ${CURRENTSUITE} /var/www/mirror/debs/*.deb"

