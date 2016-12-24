#!/bin/bash
#
# Build Debian package from realpath_turbo on PHP 7.0.
#
# VERSION       :2.0.0
# DEPENDS       :apt-get install xsltproc php-dev dh-make-php

set -e

# Download master branch
wget -qO- https://github.com/Whissi/realpath_turbo/archive/master.tar.gz | tar -xz

# Make up a PECL archive
mv -v realpath_turbo-master realpath_turbo-2.0.0
mv -v realpath_turbo-2.0.0/package.xml .

# Debian allows no tabs
sed -i -e 's|\t|    |g' package.xml

# Build package
dpkg-buildpackage -uc -us
