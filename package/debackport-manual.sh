#!/bin/bash
#
# Manually backport a Debian package.
#
# VERSION       :0.2.0
# DATE          :2017-12-02
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :https://wiki.debian.org/SimpleBackportCreation
# DEPENDS       :apt-get install devscripts
# LOCATION      :/usr/local/bin/debackport-manual.sh

# A fully manual version of debackport.sh

SUITE="jessie"
BPOREV="~bpo8+"
# Email address and name for dh_make
export DEBEMAIL="Viktor Szépe <viktor@szepe.net>"

set -e

PKG="$1"

# Debian release code name
CURRENT_SUITE="$(lsb_release -s --codename)"

# Package name from parent directory's name
test -z "$PKG" && PKG="$(basename "$PWD")"
if [ "$(uname --machine)" == "x86_64" ]; then
    ARCH="amd64"
else
    ARCH="i386"
fi

echo -n "rmadison: "
rmadison -a "$ARCH" -s "$SUITE" "$PKG"

echo "Download sources:  dget --allow-unauthenticated -x \$DSC_URL"
bash

SOURCE_PKG="$(grep -m 1 "^Source: " ./*.dsc | cut -d " " -f 2)"
if [ -z "$SOURCE_PKG" ] || [ "$(wc -l <<< "$SOURCE_PKG")" -gt 1 ]; then
    ls -d -1 -- */
    read -r -p "Please enter source package name: " SOURCE_PKG
fi
SOURCE_DIR="$(find -maxdepth 1 -type d -iname "${SOURCE_PKG}-*" | head -n 1)"

echo -n "Changing directory to: "
pushd "$SOURCE_DIR"

echo "Check and Install build dependencies:  dpkg-checkbuilddeps"
bash

echo "Indicating revision number"
sleep 2
dch --local "$BPOREV" --distribution "${CURRENT_SUITE}-backports"

echo "Build binary packages:  dpkg-buildpackage -b -us -uc"
bash

echo -n "Changing back to: "
popd

echo "Running lintian"
lintian --display-info --display-experimental --pedantic --show-overrides ./*.deb || true

echo "OK."
