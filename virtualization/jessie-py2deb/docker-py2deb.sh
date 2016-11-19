#!/bin/bash
#
# Build a Debian package from a Python package in Docker.
#
# VERSION       :0.2.1
# DATE          :2016-03-29
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :https://pypi.python.org/pypi/stdeb
# DEPENDS       :docker:szepeviktor/jessie-py2deb

Error() {
    local RET="$1"

    shift
    echo "ERROR: $*" 1>&2
    exit "$RET"
}

set -e

if [ -z "$PACKAGE" ]; then
    Error 1 'Usage:  docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="requests" szepeviktor/jessie-py2deb'
fi

TARBALL="$(python3 /usr/bin/pypi-download "$PACKAGE")"
if [ "${TARBALL:0:4}" != "OK: " ]; then
    Error 10 "Failed to download ${PACKAGE}: ${TARBALL}"
fi

# --no-python2-scripts=true means "exclude /bin scripts from Python2 package"
python3 /usr/bin/py2dsc-deb --with-python2=true --with-python3=true --no-python2-scripts=true \
    --suite "$(lsb_release -s -c)" "${TARBALL:4}"

if ! [ -d deb_dist ]; then
    ls -la
    Error 11 "Missing/invalid package"
fi

sudo cp -av deb_dist/*.deb /opt/results
lintian --color always --display-info --display-experimental --pedantic --show-overrides deb_dist/*.deb || true

echo "OK."
