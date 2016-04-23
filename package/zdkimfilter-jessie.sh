#!/bin/bash
#
# Package "z" DKIM filter for Courier MTA
#

# http://www.tana.it/sw/zdkimfilter/
PKGVERSION="1.5"
PKGRELEASE="3"
SOURCE_URL="http://www.tana.it/sw/zdkimfilter/zdkimfilter-${PKGVERSION}.tar.gz"
MAINTAINER="Viktor Szépe \\<viktor@szepe.net\\>"

set -e

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"

echo "courier-base courier-base/webadmin-configmode boolean false" | sudo debconf-set-selections -v
sudo apt-get install -qq -y wget build-essential devscripts colormake pkg-config libtool checkinstall \
    courier-mta libopendkim-dev \
    uuid-dev zlib1g-dev libunistring-dev libidn2-0-dev nettle-dev libopendbx1-dev

case "$(lsb_release -s -c)" in
    wheezy)
        LIBOPENDKIM="libopendkim7"
        ;;
    jessie)
        LIBOPENDKIM="libopendkim9"
        sudo apt-get install -qq -y libtool-bin publicsuffix
        ;;
esac
#LIBOPENDKIM="$(aptitude --disable-columns search \
# '?and(?name(^libopendkim), ?not(?exact-name(libopendkim-dev)))' -F"%p"|sort -n|tail -n 1)"

wget -O- "$SOURCE_URL" | tar xz
cd zdkimfilter-*

./configure --prefix=/usr --enable-dkimsign-setuid
colormake
colormake check

echo "'z' DKIM filter for Courier-MTA" > description-pak
sudo checkinstall -D -y --nodoc --strip --stripso --install=no \
    --pkgname="zdkimfilter" \
    --pkgversion="$PKGVERSION" \
    --pkgrelease="$PKGRELEASE" \
    --pkgarch="$(dpkg --print-architecture)" \
    --pkggroup="mail" \
    --pkgsource="$SOURCE_URL" \
    --pkglicense="GPL" \
    --maintainer="$MAINTAINER" \
    --requires="libc6 \(\>= 2.15\), libunistring0, libidn2-0, libnettle4, libopendbx1, ${LIBOPENDKIM}, courier-mta" \
    --pakdir="../"

cd ../
lintian --display-info --display-experimental --pedantic --show-overrides ./*.deb || true
sudo cp -av ./*.deb /opt/results/
echo "OK."
