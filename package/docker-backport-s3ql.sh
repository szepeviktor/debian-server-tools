#!/bin/bash
#
# Build S3QL from Debian testing.
#
# DOCS          :http://pythonhosted.org/llfuse/install.html
# DEPENDS       :stat /dev/fuse == 0666
# DEPENDS       :docker pull szepeviktor/jessie-backport

Build() {
    local PKG="$1"

    docker run --rm --tty --volume /opt/results:/opt/results \
        --cap-add SYS_ADMIN --device /dev/fuse \
        --env PACKAGE="$PKG" szepeviktor/jessie-backport
}

set -e

test -d /opt/results || mkdir /opt/results

# Build it ----------
Build python-pygal/testing
Build pytest-catchlog/testing
Build python-llfuse/testing
Build python-dugong/testing
Build s3ql/testing

echo "5×OK."

# Main IP address
ROUTER="$(ip -4 route show to default | sed -n -e '0,/^default via \(\S\+\).*$/s//\1/p')"
IP="$(ip -4 route get "$ROUTER" | sed -n -e '0,/^.*\ssrc \(\S\+\).*$/s//\1/p')"

echo "scp -r root@${IP}:/opt/results/ ./"
