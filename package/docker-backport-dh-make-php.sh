#!/bin/bash
#
# Build dh-make-php package from GitHub.
#
# DEPENDS       :docker pull szepeviktor/jessie-backport

[ -d /opt/results ] || mkdir /opt/results

# source hook ----------
cat > /opt/results/debackport-source <<"EOF"
git clone https://github.com/Avature/dh-make-php.git
cd dh-make-php/

CHANGELOG_MSG="Built from GitHub"
EOF

# Build it ----------
docker run --rm --tty -v /opt/results:/opt/results --env PACKAGE="dh-make-php" szepeviktor/jessie-backport

# Clean up
rm -f /opt/results/debackport-source
