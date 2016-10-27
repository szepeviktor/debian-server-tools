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
sudo apt-get install -t jessie-backports -y cython3 python3-py \
    python3-pytest python3-setuptools python-pytest python-setuptools
EOF

# Build it ----------
# python3-pytest-catchlog
Build pytest-catchlog/testing
# python3-llfuse, python3-llfuse-dbg
Build python-llfuse/testing
# python3-dugong
Build python-dugong/testing
Build s3ql/testing

# Clean up hook files
rm -f /opt/results/{debackport-init,debackport-pre-deps}

echo "4×OK."
echo "scp -r root@94.237.28.148:/opt/results/ ./"
