#!/bin/bash
#
# Extract or create Debian a package.
#
# VERSION       :0.2.0
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install binutils xz-utils gzip file
# LOCATION      :/usr/local/bin/deb-pack.sh

# If the package exists: extracts it, otherwise: creates it.

Deb_unpack() {
    [ -r "$DEB" ] || return 1
    file "$DEB" | grep -q "Debian binary package" || return 2

    mkdir -p "${DEBDIR}/control" || return 3
    mkdir -p "${DEBDIR}/data" || return 4

    pushd "$DEBDIR"

    # Unpack package
    ar xv "../${DEB}" || return 5

    # Unpack control
    pushd control
    echo "x - Unpack control"
    tar xf ../control.tar.* || return 6
    popd

    # Unpack data
    pushd data
    echo "x - Unpack data"
    tar xf ../data.tar.* || return 7
    popd

    popd
}

Deb_pack() {
    [ -d "$DEBDIR" ] || return 1

    pushd "$DEBDIR"

    [ -f debian-binary ] || return 2
    [ -d control ] || return 3
    [ -d data ] || return 4

    # Pack data
    pushd data

    if [ -f ../control/md5sums ]; then
        echo "Generate MD5 hashes"
        find * -type f -exec md5sum \{\} \; > ../control/md5sums || return 8
    fi

    echo "Pack data"
    [ -f ../data.tar.* ] && rm -v ../data.tar.*
    tar cJf ../data.tar.xz * || return 7

    popd

    # Debian control files
    pushd control

    [ -f ../control.tar.* ] && rm -v ../control.tar.*
    echo "Pack control"
    tar czf ../control.tar.gz * || return 6

    popd

    # Create package
    [ -r "../${DEB}" ] && rm -v "$DEB"
    ar rv "../${DEB}" debian-binary control.tar.gz data.tar.xz || return 5

    popd
}

DEB="$1"
DEBDIR="${DEB%%_*}"

echo "[WARNING] update control/Version:"
echo "[WARNING] update usr/share/doc/*/changelog.Debian"
echo

if [ -r "$DEB" ]; then
    if Deb_unpack; then
        echo "${DEB} unpacked."
    else
        echo "[ERROR] $?" 1>&2
    fi
else
    if Deb_pack; then
        echo "${DEB} packed."
    else
        echo "[ERROR] $?" 1>&2
    fi
fi
