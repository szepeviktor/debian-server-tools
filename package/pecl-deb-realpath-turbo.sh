#!/bin/bash
#
# Convert realpath_turbo PECL package on PHP 7.0 to Debian package source.
#
# VERSION       :2.0.0

set -e

wget -qO- http://www.dotdeb.org/dotdeb.gpg | sudo apt-key add -
echo "deb http://packages.dotdeb.org/ jessie all" | sudo tee /etc/apt/sources.list.d/dotdeb.list
sudo apt-get update

sudo apt-get install -qq wget ca-certificates devscripts xsltproc php-dev php-pear cdbs
# @TODO szepeviktor/dh-make-php=0.6.2
# sudo dpkg -i /opt/results/dh-make-php_0.6.2_all.deb
sudo apt-get install -f -y

# Download master branch
wget -qO- https://github.com/Whissi/realpath_turbo/archive/master.tar.gz | tar -xz

# Make up a PECL archive
mv -v realpath_turbo-master realpath_turbo-2.0.0
mv -v realpath_turbo-2.0.0/package.xml .
# Debian allows no tabs
sed -i -e 's|\t|    |g' package.xml
tar czf realpath-turbo.tgz realpath_turbo-2.0.0 package.xml
rm -rf realpath_turbo-2.0.0 package.xml

# Convert with dh-make
dh-make-pecl --package-name "php-realpath-turbo" \
    --maintainer "Viktor Szepe <viktor@szepe.net>" \
    --depends "php-common (>= 1:42), phpapi-20151012" \
    realpath-turbo.tgz

echo "OK."

# Fix files in /debian
# Package it: cd php-realpath-turbo-2.0.0/ && dpkg-buildpackage -uc -us
