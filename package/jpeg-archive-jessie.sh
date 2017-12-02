#!/bin/dash
#
# Package jpeg-archive.
#
# VERSION       :0.3.0
# DATE          :2017-12-02
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# UPSTREAM      :https://github.com/danielgtaylor/jpeg-archive

# Usage
#
# cp jpeg-archive-jessie.sh /opt/results/
# docker run --rm -it -v /opt/results:/opt/results -i --entrypoint=/opt/results/jpeg-archive-jessie.sh szepeviktor/jessie-build

PKG_RELEASE="3"
MAINTAINER="'Viktor Szépe <viktor@szepe.net>'"

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"

set -e

# Dependencies
sudo apt-get update -qq
sudo apt-get install -qq build-essential git autoconf automake pkg-config \
    nasm libtool colormake checkinstall

# Build mozjpeg
git clone https://github.com/mozilla/mozjpeg.git
cd mozjpeg/
autoreconf -fiv
./configure --with-jpeg8
colormake
sudo colormake install
sudo ln -s /opt/mozjpeg/lib64 /opt/mozjpeg/lib || true
test -f /opt/mozjpeg/lib/libjpeg.so
cd -

# Build jpeg-archive
git clone https://github.com/danielgtaylor/jpeg-archive.git
cd jpeg-archive/
# Install to the proper location
sed -i -e 's|^PREFIX ?= /usr/local|PREFIX ?= /usr|' Makefile
colormake
test -f ./jpeg-recompress

# Create debian package
PKG_VERSION="$(sed -n -e 's|^const .*VERSION = "\(.*\)".*$|\1|p' src/util.c)" #'
echo "Utilities for archiving JPEGs for long term storage." > ./description-pak
sudo checkinstall -D -y --nodoc --strip --stripso --install=no \
    --pkgname="jpeg-archive" \
    --pkgversion="$PKG_VERSION" \
    --pkgrelease="$PKG_RELEASE" \
    --pkgarch="$(dpkg --print-architecture)" \
    --pkggroup="graphics" \
    --pkgsource="https://github.com/danielgtaylor/jpeg-archive" \
    --pkglicense="GPL" \
    --maintainer="$MAINTAINER" \
    --requires="'libc6 (>= 2.14)'" \
    --pakdir="../"
cd -

# Check package
lintian --display-info --display-experimental --pedantic --show-overrides ./*.deb || true
sudo cp -av ./*.deb /opt/results/

echo "OK."
