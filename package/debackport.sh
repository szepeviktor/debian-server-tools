#!/bin/bash
#
# Backports a package from Debian jessie to wheezy
#
# VERSION       :0.1
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/debackport.sh
# DOC           :https://wiki.debian.org/SimpleBackportCreation


PKG="$1"
SUITE="jessie"
BPOREV="~bpo70+"
export DEBEMAIL="Viktor Szépe <viktor@szepe.net>"

# comment out SHORTBUILD to run debian/rules before building
SHORTBUILD="yes"
# upon "gpg: Can't check signature: public key not found" use --allow-unauthenticated
ALLOW_UNAUTH="--allow-unauthenticated"
# you may add special backport instructions
#SPECIAL_BACKPORT="yes"

die() {
    local RET="$1"
    shift

    echo -e "$(tput sgr0; tput bold; tput setaf 7; tput setab 1)${@}$(tput sgr0)" >&2
    exit "$RET"
}

msg() {
    echo "$(tput sgr0; tput dim; tput setaf 0; tput setab 3)${@}$(tput sgr0)"
}

ok_msg() {
    echo "$(tput sgr0; tput bold; tput setaf 2; tput setab 0)${@}$(tput sgr0)"
}

get_key() {
    [ -s "$TEMP" ] || die 3 "no dget output"

    local ID="$(grep -o "ID [A-F0-9]*" "$TEMP" | cut -d' ' -f2)"
    [ -z "$ID" ] && die 4 "no ID in dget output"

    gpg --keyserver "pgp.mit.edu" --recv-keys "$ID"
    gpg --export "$ID" | apt-key add - || die 5 "gpg key import error"

    rm "$TEMP"
}

dch_msg() {
    if [ -z "$SPECIAL_BACKPORT" ]; then
        dch --local "$BPOREV" --distribution "${CURRENTSUITE}-backports" "Rebuilt for ${CURRENTSUITE}."
    else
        msg "Please enter special backport instructions in the editor"
        sleep 3
        dch --local "$BPOREV" --distribution "${CURRENTSUITE}-backports"
    fi
}

# build packages as a user (tests won't fail)
[ "$(id --user)" = 0 ] && die 1 "not recommended to run debackport with root privileges!"

TEMP="$(tempfile)"
[ -z "$SHORTBUILD" ] || SHORTBUILD="yes"

# check for necessary packages
which make rmadison dget lintian &> /dev/null \
    || die 99 "apt-get -y install build-essential devscripts lintian dpkg-sig reprepro"

# get Debian release
CURRENTSUITE="$(lsb_release --codename | cut -f2)"
[ -z "$CURRENTSUITE" ] && die 9 "cannot detect current suite"

# get package name from parent dir's name
msg "check pkg"
[ -z "$PKG" ] && PKG="$(basename "$PWD")"

[ "$(uname -m)" = "x86_64" ] && ARCH="amd64" || ARCH="i386"

AVAILABLE="$(rmadison --architecture="$ARCH" --suite="$SUITE" "$PKG")"

[ -z "$AVAILABLE" ] && AVAILABLE="$(rmadison --suite="$SUITE" "$PKG")"

[ -z "$AVAILABLE" ] && die 1 "not found in ${SUITE}"
ok_msg "Source package: $AVAILABLE"

msg "Download sources"
DSCURL="$(wget -qO- "https://packages.debian.org/${SUITE}/${PKG}" | grep -o 'http.*\.dsc">\[' | cut -d'"' -f1)"
[ -z "$DSCURL" ] && die 2 "no .dsc"

dget ${ALLOW_UNAUTH} -x "$DSCURL" 2> "$TEMP" || get_key
# manual unpack:  dpkg-source -x *.dsc

msg "Find and Install missing build dependencies"
SOURCES="$(grep -m1 "^Source: " *.dsc | cut -d' ' -f2)"

if [ -z "$SOURCES" ] || [ "$(wc -l <<< "$SOURCES")" -gt 1 ]; then
    ls -1 -d */
    read -p "Please enter source package name: " SOURCES
fi
DIR="$(find -maxdepth 1 -type d -iname "${SOURCES}-*" | head -n 1)"
[ -d "$DIR" ] || die 8 "no source dir: '$DIR'"

pushd "$DIR" || die 9 "cannot change to '$DIR'"

if ! dpkg-checkbuilddeps; then
    msg "Please install missing build dependencies!"
    /bin/bash
fi

msg "Indicate backport revision number in the changelog"
dch_msg || die 20 "writing to changelog failed"

if [ -z "$SHORTBUILD" ]; then
    msg "Test if we can successfully build the package"
    fakeroot debian/rules binary || die 10 "fakeroot build failed"

    popd

    msg "Clear fakeroot build and unpack sources again"
    rm -rf "$DIR"
    dget ${ALLOW_UNAUTH} -x "$DSCURL"

    pushd "$DIR"

    dpkg-checkbuilddeps || die 11 "still dependencies not fullfilled"
    dch_msg
else
    msg 'Doing shortbuild!'
fi

msg "Build packages properly, without GPG signing them"
dpkg-buildpackage -us -uc || die 12 "build failed"

popd

ok_msg "Packages are ready."

ls *.deb | while read P; do
    ls --color=always -1 "$P"
    lintian "$P"
done

echo
# my GPG key
echo "dpkg-sig -k 451A4FBA --sign builder *.deb"
echo "cd /var/www/mirror/server/debian"
echo "reprepro remove ${CURRENTSUITE} ${PKG}"
echo "reprepro includedeb ${CURRENTSUITE} /var/www/mirror/debs/*.deb"
echo "make-index.sh"
