#!/bin/bash
#
# Build S3QL from Debian testing.
#
# DOCS          :http://pythonhosted.org/llfuse/install.html
# DEPENDS       :docker pull szepeviktor/jessie-backport

Build() {
    local PKG="$1"

    docker run --rm --tty --volume /opt/results:/opt/results \
        --env PACKAGE="$PKG" szepeviktor/jessie-backport
}

set -e

[ -d /opt/results ] || mkdir /opt/results

# init hook ----------
cat > /opt/results/debackport-init <<"EOF"
sudo chmod 0666 /dev/fuse
echo "deb http://debian-archive.trafficmanager.net/debian jessie-backports main" \
    | sudo tee /etc/apt/sources.list.d/jessie-backports.list
EOF

# pre-deps hook ----------
cat > /opt/results/debackport-pre-deps <<"EOF"
sudo apt-get install -q -t jessie-backports -y cython3 python3-py \
    python3-pytest python3-setuptools python-pytest python-setuptools
EOF

# Build it ----------
Build pytest-catchlog/testing
Build python-llfuse/testing
Build python-dugong/testing
Build s3ql/testing

# Clean up hook files
rm -f /opt/results/{debackport-init,debackport-pre-deps}

set +x
# First interface by name the eth* with an IPv4 address
IP="$(ifconfig|sed -n -e '/^eth/{n;s/^\s*inet addr:\([0-9.]\+\)\s.*$/\1/p;q}')"
echo "4×OK."
echo "scp -r root@${IP}:/opt/results/ ./"
