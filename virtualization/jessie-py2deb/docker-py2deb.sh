#!/bin/bash
#
# Build a Debian package from a Python package in Docker.
#
# VERSION       :0.1.0
# DATE          :2016-01-31
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :https://pypi.python.org/pypi/stdeb
# DEPENDS       :docker:szepeviktor/jessie-py2deb
# LOCATION      :/usr/local/bin/docker-py2deb.sh

# Usage
#     docker create --env PACKAGE="requests" --name=py2deb --user=1000 --entrypoint=/usr/local/bin/docker-py2deb.sh --workdir=/home/debian szepeviktor/jessie-py2deb
#     docker start -i py2deb && docker cp py2deb:/home/debian/deb_dist ./ && docker rm py2deb

Error() {
    local RET="$1"

    shift
    echo "ERROR: $*" 1>&2
    exit "$RET"
}

TARBALL="$(python3 /usr/bin/pypi-download "$PACKAGE")"
if [ "${TARBALL:0:4}" != "OK: " ]; then
    Error 1 "Failed to download ${PACKAGE}: ${TARBALL}"
fi

# --no-python2-scripts=true means "exclude /bin scripts from Python2 package"
python3 /usr/bin/py2dsc-deb --with-python2=true --with-python3=true --no-python2-scripts=true \
    --suite "$(lsb_release -cs)" "${TARBALL:4}" || Error 2 "Package build failure"

if [ -d deb_dist ]; then
    lintian --color always deb_dist/*.deb
    ls -l deb_dist/*.deb
    echo "OK."
else
    ls -la
    Error 10 "Missing/invalid package"
fi
