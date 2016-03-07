#!/bin/bash
#
# Package "z" DKIM filter for Courier MTA
#

# http://www.tana.it/sw/zdkimfilter/
PKGVERSION="1.5"
SOURCE_URL="http://www.tana.it/sw/zdkimfilter/zdkimfilter-${PKGVERSION}.tar.gz"
MAINTAINER="viktor@szepe.net"

set +e

apt-get install -qq -y build-essential devscripts colormake pkg-config libtool checkinstall \
    courier-mta libopendkim-dev \
    uuid-dev zlib1g-dev libunistring-dev libidn2-0-dev nettle-dev libopendbx1-dev

case "$(lsb_release -s -c)" in
    wheezy)
        LIBOPENDKIM="libopendkim7"
        ;;
    jessie)
        LIBOPENDKIM="libopendkim9"
        apt-get install -qq -y libtool-bin publicsuffix
        ;;
esac
#LIBOPENDKIM="$(aptitude --disable-columns search \
# '?and(?name(^libopendkim), ?not(?exact-name(libopendkim-dev)))' -F"%p"|sort -n|tail -n 1)"

wget -O- "$SOURCE_URL" | tar xz
cd zdkimfilter-*

./configure --prefix=/usr --enable-dkimsign-setuid; echo $?
colormake; echo $?
colormake check; echo $?

# Fix checkinstall
sed -i -e "s;\(^\s*REQUIRES=\)\`eval echo \$1\`;\1\"\`eval \"echo '\$1'\"\`\";" /usr/bin/checkinstall

checkinstall -D -y --nodoc --strip --maintainer "$MAINTAINER" \
    --pkgname "zdkimfilter" --pkggroup "mail" \
    --pkgversion "$PKGVERSION" --pkgrelease 2 \
    --requires "courier-mta ${LIBOPENDKIM} libunistring0 libidn2-0 libnettle4 libopendbx1"

lintian zdkimfilter_*_amd64.deb
