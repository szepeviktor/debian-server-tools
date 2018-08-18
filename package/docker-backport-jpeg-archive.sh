#!/bin/bash
#
# Build jpeg-archive package from git master branch.
#
# DEPENDS       :docker pull szepeviktor/stretch-backport

PKG_VERSION="jpeg-archive_2.2.0"

test -d /opt/results || mkdir /opt/results

# Source hook
cat >/opt/results/debackport-source <<"EOT"
# Build mozjpeg
# https://github.com/mozilla/mozjpeg/blob/master/BUILDING.txt#L10
sudo apt-get install -qq build-essential git autoconf automake pkg-config libtool nasm
git clone "https://github.com/mozilla/mozjpeg.git"
(
    cd mozjpeg/
    autoreconf -fiv
    ./configure --with-jpeg8
    make
    sudo make install
)
rm -rf mozjpeg/
# Link lib/ to lib64/
sudo ln -s /opt/mozjpeg/lib64 /opt/mozjpeg/lib

# Download source and packaging files
git clone "https://github.com/danielgtaylor/jpeg-archive.git"
git clone "https://github.com/szepeviktor/debian-server-tools.git"

cd jpeg-archive/
tar -czf ../${PACKAGE}.orig.tar.gz .

mv ../debian-server-tools/package/jpeg-archive/debian .
tar -czf ../${PACKAGE}.debian.tar.gz debian

# Set changelog message
CHANGELOG_MSG="Built from git/master"
EOT


# Build package
docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="$PKG_VERSION" szepeviktor/stretch-backport
rm -f /opt/results/debackport-source
