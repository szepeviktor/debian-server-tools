#!/bin/bash
#
# Build munin package from Debian debian-experimental branch.
#
# DEPENDS       :docker pull szepeviktor/stretch-backport

test -d /opt/results || mkdir /opt/results

# source hook
cat >/opt/results/debackport-source <<"EOF"
#git clone -b debian-experimental "https://salsa.debian.org/debian/munin.git" munin
git clone -b debian-experimental "https://salsa.debian.org/sumpfralle-guest/munin.git" munin
cd munin/
# Remove "debian/" from version
sed -e 's%git describe --long %&| sed -e "s#^debian/##"%' -i getversion
# Debug
#sed -e 's/make -C doc html man/#&/' -i debian/rules
#sed -e 's/# export DH_VERBOSE=1/export DH_VERBOSE=1/' -i debian/rules
#sed -e '1s|#!/bin/sh|#!/bin/bash -x|' -i getversion
# quilt
PKG_VERSION="$(dpkg-parsechangelog --show-field Version)"
tar -cJf ../munin_${PKG_VERSION%-*}.orig.tar.xz .
CHANGELOG_MSG="From Debian git/debian-experimental"
EOF


# pre-deps hook
cat >/opt/results/debackport-pre-deps <<"EOF"
# debhelper v11
echo "deb http://debian-archive.trafficmanager.net/debian stretch-backports main" \
    | sudo -- tee /etc/apt/sources.list.d/backports.list
sudo apt-get update
sudo apt-get install -y debhelper/stretch-backports
# HTTP::Server::Simple::CGI
sudo apt-get install -y libhttp-server-simple-perl
# HTTP::Server::Simple::CGI::PreFork from buster
wget "http://ftp.de.debian.org/debian/pool/main/libh/libhttp-server-simple-cgi-prefork-perl/libhttp-server-simple-cgi-prefork-perl_6-1_all.deb"
sudo dpkg -i libhttp-server-simple-cgi-prefork-perl_*_all.deb
sudo rm libhttp-server-simple-cgi-prefork-perl_*_all.deb
sudo apt-get install -y -f
# Alien::RRDtool and inc::latest
sudo apt-get install -y pkg-config graphviz libxml2-dev libpango1.0-dev libcairo2-dev \
    libfile-sharedir-perl libtest-requires-perl libmodule-build-perl
sudo PERL_MM_USE_DEFAULT=1 cpan -i inc::latest
sudo PERL_MM_USE_DEFAULT=1 cpan -i Alien::RRDtool
EOF


# Build
docker run --rm --tty -v /opt/results:/opt/results --env PACKAGE="munin" szepeviktor/stretch-backport
rm -f /opt/results/{debackport-source,debackport-pre-deps}
