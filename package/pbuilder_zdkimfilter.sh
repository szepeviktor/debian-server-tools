#!/bin/bash
#
# Package "z" DKIM filter for Courier MTA
#

# http://www.tana.it/sw/zdkimfilter/
PKGVERSION="1.5"
SOURCE_URL="http://www.tana.it/sw/zdkimfilter/zdkimfilter-${PKGVERSION}.tar.gz"
MAINTAINER="viktor@szepe.net"

apt-get install -y --force-yes build-essential colormake pkg-config libtool checkinstall \
    courier-mta libopendkim-dev \
    uuid-dev zlib1g-dev libunistring-dev libidn2-0-dev nettle-dev libopendbx1-dev

# Only in jessie
apt-get install -y --force-yes libtool-bin publicsuffix || true

wget -O- "$SOURCE_URL" | tar xz
cd zdkimfilter-*

./configure --prefix=/usr --enable-dkimsign-setuid; echo $?
colormake; echo $?
colormake check; echo $?

# Patch checkinstall
sed -i "s/\(^\s*REQUIRES=\)\`eval echo \$1\`/\1\"\`eval \"echo '\$1'\"\`\"/" /usr/bin/checkinstall

checkinstall -D -y --nodoc --strip \
    --pkgname zdkimfilter --pkggroup mail --pkgversion "$PKGVERSION" \
    --pkgrelease 1  --maintainer "$MAINTAINER" |
    --requires 'courier-mta libopendkim libunistring0 libidn2-0 libnettle4 libopendbx1'

which lintian && lintian zdkimfilter_*_amd64.deb
