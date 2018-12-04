#!/bin/bash
#
# Extract and create a Debian package.
#
# VERSION       :0.3.0
# DATE          :2017-06-23
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install binutils xz-utils gzip file
# LOCATION      :/usr/local/bin/deb-pack.sh

# Usage
#
# Unpack (existing .deb file)
#     deb-pack.sh lsb-release_9.20161125_all.deb
#
# Pack (non-existent .deb file)
#     deb-pack.sh lsb-release_9.20170623_all.deb

Deb_unpack()
{
    test -r "$DEB" || return 1
    file "$DEB" | grep -q -F 'Debian binary package' || return 2

    mkdir -p "${DEBDIR}/control" || return 3
    mkdir -p "${DEBDIR}/data" || return 4

    # Unpack package
    ( cd "${DEBDIR}/"; ar xv "../${DEB}" ) || return 5

    echo "x - Unpack control"
    tar -C "${DEBDIR}/control/" -xf "${DEBDIR}/control.tar."* || return 6

    echo "x - Unpack data"
    tar -C "${DEBDIR}/data/" -xf "${DEBDIR}/data.tar."* || return 7
}

Deb_pack()
{
    test -d "$DEBDIR" || return 1

    test -f "${DEBDIR}/debian-binary" || return 2
    test -d "${DEBDIR}/control" || return 3
    test -d "${DEBDIR}/data" || return 4

    # Pack data
    if [ -f "${DEBDIR}/control/md5sums" ]; then
        echo "Update MD5 hashes"
        (
            cd "${DEBDIR}/data/"
            find . -type f -printf '%P\n' | xargs -L 1 md5sum
        ) >"${DEBDIR}/control/md5sums" || return 8
    fi

    echo "Pack data"
    if compgen -G "${DEBDIR}/data.tar.*" >/dev/null; then
        rm -v "${DEBDIR}/data.tar."*
    fi
    tar -C "${DEBDIR}/data/" -cJf "${DEBDIR}/data.tar.xz" . || return 7

    # Debian control files
    if compgen -G "${DEBDIR}/control.tar.*" >/dev/null; then
        rm -v "${DEBDIR}/control.tar."*
    fi
    echo "Pack control"
    GZIP="-n" tar -C "${DEBDIR}/control/" -czf "${DEBDIR}/control.tar.gz" . || return 6

    # Create package
    if [ -r "${DEBDIR}/${DEB}" ]; then
        rm -v "${DEBDIR}/${DEB}"
    fi
    (
        cd "${DEBDIR}/"
        ar rvD "../${DEB}" debian-binary control.tar.gz data.tar.xz
    ) || return 5
}

DEB="$1"

set -e

DEBDIR="${DEB%%_*}"

if [ -r "$DEB" ]; then
    if Deb_unpack; then
        echo "${DEB} unpacked OK."
    else
        echo "[ERROR] ${?}" 1>&2
    fi
else
    echo "[WARNING] update Version: header in control"
    echo "[WARNING] update changelog.Debian"
    echo

    if Deb_pack; then
        echo "${DEB} packed OK."
    else
        echo "[ERROR] ${?}" 1>&2
    fi
fi
