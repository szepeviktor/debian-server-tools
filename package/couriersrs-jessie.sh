#!/bin/bash
#
# Courier SRS
#
# http://archive.debian.org/debian/pool/main/libs/libsrs2/libsrs2_1.0.18-4.dsc
#
# echo 'dch --newversion "1.0.18-5" --distribution "stable" "$CHANGELOG_MSG"' > /opt/results/debackport-changes
# docker run --rm --tty -v /opt/results:/opt/results --env PACKAGE="http://archive.debian.org/debian/pool/main/libs/libsrs2/libsrs2_1.0.18-4.dsc" szepeviktor/jessie-backport
# cp -v ./couriersrs-jessie.sh /opt/results/
# docker run --rm --tty -v /opt/results:/opt/results --entrypoint="/opt/results/couriersrs-jessie.sh" szepeviktor/jessie-backport

PKGVERSION="0.1.2"
PKGRELEASE="3"
MAINTAINER='Viktor Szépe \<viktor@szepe.net\>'

set -e

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"

sudo -- dpkg -i /opt/results/libsrs2-*_amd64.deb
echo "courier-base courier-base/webadmin-configmode boolean false" | sudo -- debconf-set-selections -v
sudo -- apt-get install -y git checkinstall build-essential autoconf2.64 automake1.11 colormake libpopt-dev courier-mta

git clone "https://github.com/szepeviktor/couriersrs"
cd couriersrs/

./configure --prefix=/usr --sysconfdir=/etc
colormake

echo "Forwarding messages in courier using SRS" >description-pak
# http://checkinstall.izto.org/docs/README
sudo checkinstall -D -y --nodoc --strip --stripso --install=no \
    --pkgname="couriersrs" \
    --pkgversion="$PKGVERSION" \
    --pkgrelease="$PKGRELEASE" \
    --pkgarch="$(dpkg --print-architecture)" \
    --pkggroup="mail" \
    --pkgsource="https://github.com/szepeviktor/couriersrs" \
    --pkglicense="GPL" \
    --maintainer="$MAINTAINER" \
    --requires='libc6 \(\>= 2.15\), libsrs2-0 \(\>= 1.0.18\), courier-mta' \
    --pakdir="../"

cd ../
lintian --display-info --display-experimental --pedantic --show-overrides ./*.deb || true
sudo -- cp -av ./*.deb /opt/results/
echo "OK."
