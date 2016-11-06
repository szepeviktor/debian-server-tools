#!/bin/bash
#
# Convert realpath_turbo PECL package to Debian package.
#
# VERSION       :2.0.0

apt-get install -y wget ca-certificates php5-dev devscripts xsltproc dh-make-php

# Download master branch
wget -qO- https://github.com/Whissi/realpath_turbo/archive/master.tar.gz | tar -xz

# Make up a PECL archive
mv -v realpath_turbo-master realpath_turbo-2.0.0
mv -v realpath_turbo-2.0.0/package.xml .
# Debian allows no tabs
sed -i -e 's|\t|    |g' package.xml
tar czf realpath-turbo.tar.gz realpath_turbo-2.0.0 package.xml
rm -vrf realpath_turbo-2.0.0 package.xml

# Convert with dh-make
dh-make-pecl --package-name "realpath-turbo" --php55-conf --maintainer "Viktor Szepe <viktor@szepe.net>" \
    realpath-turbo.tar.gz
# Build Debian package
(
    cd php-realpath-turbo-2.0.0/ || exit 1
    # Fix package name
    sed -i -e 's|^PECL_PKG_NAME=realpath-turbo$|PECL_PKG_NAME=realpath_turbo|' debian/rules
    dpkg-buildpackage -uc -us
)

lintian --display-info --display-experimental --pedantic --show-overrides ./*.deb
echo "OK."
