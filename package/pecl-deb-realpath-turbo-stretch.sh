#!/bin/bash
#
# Convert realpath_turbo PECL package to Debian package.
#
# VERSION       :2.0.0

apt-get install -y wget ca-certificates php7.0-dev devscripts xsltproc

# Debian strech has no dh-make-php
wget -nv http://deb.debian.org/debian/pool/main/d/dh-make-php/dh-make-php_0.4.0_all.deb
# Create fake package providing php5-dev and php5-cli
apt-get install -qq equivs cdbs
echo -e "Section: misc\nPriority: optional\nStandards-Version: 3.9.2\n" > php5.equ
echo -e "Package: php5-dev\nDepends: php7.0-dev\nProvides: php5-cli\nDescription: For dh-make-php" >> php5.equ
equivs-build php5.equ
dpkg -i php5-dev_1.0_all.deb dh-make-php_0.4.0_all.deb
ln -s /usr/bin/phpize /usr/local/bin/phpize5
ln -s /usr/bin/php-config /usr/local/bin/php-config5
rm -f php5-dev_1.0_all.deb dh-make-php_0.4.0_all.deb

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
