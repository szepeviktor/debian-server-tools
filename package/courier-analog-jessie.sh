#!/bin/bash
#
# Package Courier-analog
#
# docker run --rm --tty -v /opt/results:/opt/results --env PACKAGE="http://deb.debian.org/debian/pool/main/c/courier-unicode/courier-unicode_1.4-2.dsc" szepeviktor/jessie-backport
# cp -v ./courier-analog-jessie.sh /opt/results/
# docker run --rm --tty -v /opt/results:/opt/results --entrypoint="/opt/results/courier-analog-jessie.sh" szepeviktor/jessie-backport

# http://www.courier-mta.org/download.html#analog
PKGVERSION="0.17"
PKGRELEASE="1"
SOURCE_URL="https://sourceforge.net/projects/courier/files/analog/${PKGVERSION}/courier-analog-${PKGVERSION}.tar.bz2/download"
MAINTAINER="Viktor Szépe \\<viktor@szepe.net\\>"

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"

set -e

sudo dpkg -R -i /opt/results/ || true
sudo apt-get update -qq
sudo apt-get install -qq -f wget bzip2 build-essential devscripts colormake pkg-config libtool checkinstall

if [ "$(dpkg-query --showformat="\${Status}" --show libcourier-unicode-dev 2> /dev/null)" != "install ok installed" ]; then
    echo "libcourier-unicode-dev needs to be installed" 1>&2
    exit 1
fi

wget -nv -O- "$SOURCE_URL" | tar xj

(
    cd courier-analog-*
    ./configure --prefix=/usr
    colormake
    colormake check

    echo "Generate log summaries for the Courier mail server." > description-pak
    sudo checkinstall -D -y --nodoc --strip --stripso --install=no \
        --pkgname="courier-analog" \
        --pkgversion="$PKGVERSION" \
        --pkgrelease="$PKGRELEASE" \
        --pkgarch="$(dpkg --print-architecture)" \
        --pkggroup="mail" \
        --pkgsource="$SOURCE_URL" \
        --pkglicense="GPL" \
        --maintainer="$MAINTAINER" \
        --requires="libc6 \(\>= 2.19\), libcourier-unicode1" \
        --pakdir="../"
)

lintian --display-info --display-experimental --pedantic --show-overrides ./*.deb || true
sudo cp -av ./*.deb /opt/results/

echo "OK."

# Courier-analog usage
#     courier-analog --smtpinet --smtpitime --smtpierr --smtpos --smtpod --smtpof \
#         --imapnet --imaptime --imapbyuser --imapbylength --imapbyxfer \
#         --noisy --title="REPORT TITLE" /var/log/mail.log
