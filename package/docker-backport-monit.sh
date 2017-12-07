#!/bin/bash
#
# Build monit package from testing.
#
# DEPENDS       :docker pull szepeviktor/jessie-backport

[ -d /opt/results ] || mkdir /opt/results

# pre-deps hook ----------
cat > /opt/results/debackport-pre-deps <<"EOT"
# Change dependencies
sed -i -e 's/debhelper (>= 10)/debhelper (>= 9)/' debian/control

# automake-1.15 from testing
sudo apt-get install -y autoconf autotools-dev
wget -P /tmp/ "http://ftp.de.debian.org/debian/pool/main/a/automake-1.15/automake_1.15-6_all.deb"
sudo dpkg -i /tmp/automake_*_all.deb
EOT

# Build it ----------
docker run --rm --tty -v /opt/results:/opt/results --env PACKAGE="monit/testing" szepeviktor/jessie-backport

# Clean up
rm -f /opt/results/debackport-pre-deps
