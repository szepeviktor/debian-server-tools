#!/bin/bash
#
# Extracts or creates Debian packages.
# If package exists: unpacks, if does not exist: packs.
#
# VERSION       :0.2
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/deb-pack.sh
# DEPENDS:      :apt-get install binutils xz-utils gzip file


function deb_unpack() {
    [ -r "$DEB" ] || return 1
    file "$DEB" | grep -q "Debian binary package" || return 2

    mkdir -p "${DEBDIR}/control" || return 3
    mkdir -p "${DEBDIR}/data" || return 4

    pushd "$DEBDIR"

    # unpack deb
    ar xv "../${DEB}" || return 5

    # unpack control
    pushd control
    echo "x - unpack control"
    tar xf ../control.tar.* || return 6
    popd

    # unpack data
    pushd data
    echo "x - unpack data"
    tar xf ../data.tar.* || return 7
    popd

    popd
}

function deb_pack() {
    [ -d "$DEBDIR" ] || return 1

    pushd "$DEBDIR"

    [ -f debian-binary ] || return 2
    [ -d control ] || return 3
    [ -d data ] || return 4

    # pack data
    pushd data

    if [ -f ../control/md5sums ]; then
        echo "generate md5sums"
        find * -type f -exec md5sum \{\} \; > ../control/md5sums || return 8
    fi

    echo "pack data"
    [ -f ../data.tar.* ] && rm -v ../data.tar.*
    tar cJf ../data.tar.xz * || return 7

    popd

    # Debian control files
    pushd control

    [ -f ../control.tar.* ] && rm -v ../control.tar.*
    echo "pack control"
    tar czf ../control.tar.gz * || return 6

    popd

    # create .deb
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
    if deb_unpack; then
        echo "${DEB} unpacked."
    else
        echo "error: $?" >&2
    fi

else
    if deb_pack; then
        echo "${DEB} packed."
    else
        echo "error: $?" >&2
    fi
fi

