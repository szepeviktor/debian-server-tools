#!/bin/bash
#
# Backport a Debian package.
#
# VERSION       :0.1.1
# REFS          :http://backports.debian.org/Contribute/#index6h3
# DOCS          :https://wiki.debian.org/SimpleBackportCreation

# A) Build from source package name/release codename
#
# Get source package name:
#     apt-get source --dry-run $PACKAGE|grep "^Fetch source"
#
# B) Build from .dsc file URL
#
# Get the .dsc file at
#     https://www.debian.org/distrib/packages#search_packages
#
# Package versioning:
#     ${UPSTREAM_VERSION}[-${DEBIAN_REVISION}]~bpo${DEBIAN_RELEASE}+${BUILD_INT}
#
# Apache backport: ?openssl/sid? spdylay nghttp2 apr-util apache2
# Courier backport: courier-unicode courier-authlib courier

# @TODO Sign and upload to a repo.

set -e

export DEBEMAIL="Viktor Szépe <viktor@szepe.net>"

ALLOW_UNAUTH="--allow-unauthenticated"

Error() {
    local RET="$1"

    shift
    echo "ERROR: $*" 1>&2
    exit "$RET"
}

if [ -z "$PACKAGE" ]; then
    Error 1 'Usage:  docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="openssl/testing" szepeviktor/jessie-backport'
fi

# Only for amd64
[ "$(uname -m)" == "x86_64" ] || Error 2 "Tested only on amd64"

CURRENT_RELEASE="$(lsb_release -s --codename)"

# Install .deb dependencies
sudo dpkg -R -i /opt/results/ || true
sudo apt-get update -qq
sudo apt-get install -y -f

if [ "${PACKAGE%.dsc}" == "$PACKAGE" ]; then
    # from source "package name/release codename"
    RELEASE="${PACKAGE#*/}"
    echo "deb-src http://ftp.hu.debian.org/debian ${RELEASE} main" | sudo tee -a /etc/apt/sources.list
    sudo apt-get update -qq
    apt-get source "$PACKAGE"
    # "dpkg-source: info: extracting pkg in pkg-1.0.0"
    cd "${PACKAGE%/*}-"*
    CHANGELOG_MSG="Built from ${PACKAGE}"
else
    # from .dsc URL
    dget --extract ${ALLOW_UNAUTH} "$PACKAGE"
    cd "$(basename "$PACKAGE" | cut -d "_" -f 1)-"*
    CHANGELOG_MSG="Built from DSC file: ${PACKAGE}"
fi

# Remove version number constraints and alternatives
DEPENDENCIES="$(dpkg-checkbuilddeps 2>&1 \
    | sed -e 's/^.*Unmet build dependencies: //' -e 's/ ([^)]\+)//g' -e 's/\(\S\+\)\( | \S\+\)\+/\1/g')"
if [ -n "$DEPENDENCIES" ]; then
    sudo apt-get install -y ${DEPENDENCIES}
fi

# Double check
dpkg-checkbuilddeps

dch --bpo --distribution "${CURRENT_RELEASE}-backports" "$CHANGELOG_MSG"

dpkg-buildpackage -us -uc

cd ..
lintian *.deb || true
sudo cp -av *.deb /opt/results
echo "OK."
