#!/bin/bash
#
# Build S3QL from Debian testing.
#
# DOCS          :http://pythonhosted.org/llfuse/install.html
# DEPENDS       :docker pull szepeviktor/jessie-backport

Build() {
    local PKG="$1"

    docker run --rm --tty --volume /opt/results:/opt/results \
        --cap-add SYS_ADMIN --device /dev/fuse \
        --env PACKAGE="$PKG" szepeviktor/jessie-backport
}

set -e

[ -d /opt/results ] || mkdir /opt/results

# init hook ----------
cat > /opt/results/debackport-init <<"EOF"
sudo chmod -v 0666 /dev/fuse
echo "deb http://debian-archive.trafficmanager.net/debian jessie-backports main" \
    | sudo tee /etc/apt/sources.list.d/jessie-backports.list
EOF

# pre-deps hook ----------
cat > /opt/results/debackport-pre-deps <<"EOF"
sudo apt-get install -q -t jessie-backports -y cython3 python3-py \
    python3-pytest python3-setuptools python-pytest python-setuptools \
    python3-pytest-catchlog python-pytest-catchlog
EOF

# Build it ----------
# https://anonscm.debian.org/cgit/python-modules/packages/pytest-catchlog.git/commit/?id=7cd007a50fe894534d61baefbac00a5d9c3e70ff
#Build pytest-catchlog/testing
Build python-llfuse/testing
Build python-dugong/testing
Build s3ql/testing

# Clean up hook files
rm -f /opt/results/{debackport-init,debackport-pre-deps}

set +x

echo "4×OK."

# Main IP address
ROUTER="$(ip -4 route show to default | sed -n -e '0,/^default via \(\S\+\).*$/s//\1/p')"
IP="$(ip -4 route get "$ROUTER" | sed -n -e '0,/^.*\ssrc \(\S\+\).*$/s//\1/p')"

echo "scp -r root@${IP}:/opt/results/ ./"
