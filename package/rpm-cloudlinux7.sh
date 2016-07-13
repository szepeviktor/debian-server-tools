#!/bin/bash
#
# Download and unpack an RPM package for CloudLinux.
#
# REPOS         :http://repo.cloudlinux.com/cloudlinux/migrate/release-files/cloudlinux/${RELEASE}/${ARCH}/cloudlinux${RELEASE}-release-current.${CPU}.rpm
# DEPENDS       :apt-get install rpm2cpio
# CentOS        :http://pkgs.repoforge.org/${PACKAGE}/

CL_REPO1="http://repo.cloudlinux.com/cloudlinux/7/updates/x86_64/Packages/"
CL_REPO2="http://repo.cloudlinux.com/cloudlinux/7/os/x86_64/Packages/"

Get_rpm() {
    local REPO
    local PKG

    REPO="$CL_REPO1"
    PKG="$(wget -qO- "$REPO" | grep -o -m 1 "\"${RPM}-.*\.rpm\"" | cut -d '"' -f 2)"
    if [ -z "$PKG" ]; then
        REPO="$CL_REPO2"
        PKG="$(wget -qO- "$REPO" | grep -o -m 1 "\"${RPM}-.*\.rpm\"" | cut -d '"' -f 2)"
    fi
    [ -z "$PKG" ] && return 10

    wget -nv "${REPO}${PKG}" && echo "$PKG"
}


RPM="$1"
[ -z "$RPM" ] && exit 1

PKG="$(Get_rpm)"
[ -z "$PKG" ] && exit 2

rpm2cpio "$PKG" > "${PKG}.cpio" && rm -f "$PKG"
cpio -vit < "${PKG}.cpio"

echo "mkdir -p ./usr/bin; cat ${PKG}.cpio|cpio -vi FILE-NAME"
