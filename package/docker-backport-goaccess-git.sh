#!/bin/bash
#
# Build goaccess package from git master branch.
#
# DEPENDS       :docker pull szepeviktor/stretch-backport

test -d /opt/results || mkdir /opt/results

# Source hook
cat <<"EOF" > /opt/results/debackport-source
# Download source and packaging files
git clone https://github.com/allinurl/goaccess.git
git clone https://github.com/szepeviktor/debian-server-tools.git

cd goaccess/

# Raise MAX_IGNORE_IPS = 2048
sed -e 's|^#define MAX_IGNORE_IPS .*$|#define MAX_IGNORE_IPS 2048|' -i src/settings.h
tar -cJf ../${PACKAGE}.orig.tar.xz .

mv ../debian-server-tools/package/goaccess/debian .
tar -cJf ../${PACKAGE}.debian.tar.xz debian

# Set changelog message
CHANGELOG_MSG="Built from git/master@$(git rev-parse --short HEAD), MAX_IGNORE_IPS 2048"
EOF

# Build it
# EDIT release version
docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="goaccess_1.2" szepeviktor/stretch-backport

rm -f /opt/results/debackport-source
