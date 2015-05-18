#/bin/dash
#
# Generate jpeg-archive Debian package.
#
# VERSION       :0.2
# DATE          :2015-05-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install pbuilder

# Usage
#
# pbuilder --execute --bindmounts /var/cache/pbuilder/result -- ./pbuilder_jpeg-arichiver.sh
#
# Results
#
# ls -l /var/cache/pbuilder/result

set -x

RESULTS="/var/cache/pbuilder/result"
MAINTAINER="viktor@szepe.net"

# Prerequisites
#sed -i 's/main$/main contrib non-free/g' /etc/apt/sources.list
apt-get update && apt-get install -y build-essential git autoconf pkg-config nasm libtool checkinstall
cd /usr/src/

# Build mozjpeg
git clone https://github.com/mozilla/mozjpeg.git && cd mozjpeg/
autoreconf -fiv && ./configure --with-jpeg8 && make && make install
#make deb
cd ..
[ -f /opt/mozjpeg/lib64/libjpeg.so ] || exit 1

# Build jpeg-archive
git clone https://github.com/danielgtaylor/jpeg-archive.git && cd jpeg-archive/
sed -i 's/^PREFIX ?= \/usr\/local/PREFIX ?= \/usr/' Makefile
PKGVERSION="$(sed -n 's/^const .*VERSION = "\(.*\)".*$/\1/p' src/util.c)" #'
echo 'Utilities for archiving JPEGs for long term storage.' > ./description-pak
make
[ -f ./jpeg-recompress ] || exit 2

# Patch checkinstall
sed -i "s/\(^\s*REQUIRES=\)\`eval echo \$1\`/\1\"\`eval \"echo '\$1'\"\`\"/" /usr/bin/checkinstall

# Create debian package
checkinstall -D -y --nodoc --strip \
    --pkgname jpeg-archive --pkggroup graphics --pkgversion "$PKGVERSION" \
    --pkgrelease 2 --requires 'libc6 (>= 2.14)' --maintainer "$MAINTAINER"
ls ./jpeg-archive*.deb || exit 3

# Results
mv -v ./jpeg-archive*.deb "$RESULTS"
cd ../
