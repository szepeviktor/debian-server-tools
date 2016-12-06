#!/bin/bash
#
# Package "z" DKIM filter for Courier MTA.
#
# VERSION       :1.5.4
# DATE          :2016-12-05
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# UPSTREAM      :http://www.tana.it/sw/zdkimfilter/

# Usage
#
# cp zdkimfilter-jessie.sh /opt/results/
# docker run --rm -it -v /opt/results:/opt/results -i --entrypoint=/opt/results/zdkimfilter-jessie.sh szepeviktor/jessie-build

PKGVERSION="1.5"
PKGRELEASE="4"
SOURCE_URL="http://www.tana.it/sw/zdkimfilter/zdkimfilter-${PKGVERSION}.tar.gz"
MAINTAINER="Viktor Szépe \\<viktor@szepe.net\\>"

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"

set -e

echo "courier-base courier-base/webadmin-configmode boolean false" | sudo debconf-set-selections -v
sudo apt-get update -qq
sudo apt-get install -qq \
    wget build-essential devscripts colormake pkg-config libtool-bin publicsuffix checkinstall \
    courier-mta libopendkim-dev \
    uuid-dev zlib1g-dev libunistring-dev libidn2-0-dev nettle-dev libopendbx1-dev

#    aptitude --disable-columns --display-format %p search \
#        '?and(?name(^libopendkim), ?not(?exact-name(libopendkim-dev)))' | sort -n | tail -n 1
case "$(lsb_release -s -c)" in
    jessie)
        #LIBOPENDKIM="libopendkim9"
        # Backported
        sudo dpkg -i /opt/results/libopendkim11*.deb /opt/results/libopendkim-dev*.deb
        LIBOPENDKIM="libopendkim11"
        ;;
    stretch)
        LIBOPENDKIM="libopendkim11"
        ;;
esac

wget -O- "$SOURCE_URL" | tar xz
cd zdkimfilter-*

./configure --prefix=/usr --enable-dkimsign-setuid
colormake
colormake check

echo "'z' DKIM filter for Courier-MTA" > description-pak
# Recommends: opendkim-tools
# Mark as config: zdkimfilter.conf.dist -> zdkimfilter.conf
sudo checkinstall -D -y --nodoc --strip --stripso --install=no \
    --pkgname="zdkimfilter" \
    --pkgversion="$PKGVERSION" \
    --pkgrelease="$PKGRELEASE" \
    --pkgarch="$(dpkg --print-architecture)" \
    --pkggroup="mail" \
    --pkgsource="$SOURCE_URL" \
    --pkglicense="GPL" \
    --maintainer="$MAINTAINER" \
    --requires="libc6 \(\>= 2.19\), libunistring0, libidn2-0, libnettle4, libopendbx1, ${LIBOPENDKIM}, courier-mta" \
    --pakdir="../"

cd -
# --no-tag-display-limit
lintian --display-info --display-experimental --pedantic --show-overrides ./*.deb || true
sudo cp -av ./*.deb /opt/results/

echo "OK."
