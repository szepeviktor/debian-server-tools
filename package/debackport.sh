#!/bin/bash
#
# Backport a Debian package to stable.
#
# VERSION       :0.1.1
# DATE          :2018-07-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/debackport.sh
# REFS          :http://backports.debian.org/Contribute/#index6h3
# DOCS          :https://wiki.debian.org/SimpleBackportCreation


PKG="$1"
SUITE="stretch"
# ${upstream_version}[-${debian_revision}]~bpo${debian_release}+${build_int}
BPOREV="~bpo9+"
export DEBEMAIL="Viktor Szépe <viktor@szepe.net>"

# Comment out SHORTBUILD to run debian/rules before building
SHORTBUILD="yes"
# Upon "gpg: Can't check signature: public key not found" use --allow-unauthenticated
ALLOW_UNAUTH="--allow-unauthenticated"
# Add special backport instructions to changelog
#SPECIAL_BACKPORT="yes"

die()
{
    local RET="$1"
    shift

    echo -e "$(tput sgr0; tput bold; tput setaf 7; tput setab 1)${*}$(tput sgr0)" >&2
    exit "$RET"
}

msg()
{
    echo "$(tput sgr0; tput dim; tput setaf 0; tput setab 3)${*}$(tput sgr0)"
}

ok_msg()
{
    echo "$(tput sgr0; tput bold; tput setaf 2; tput setab 0)${*}$(tput sgr0)"
}

get_key()
{
    local ID

    if [ ! -s "$TEMP" ]; then
        die 3 "no dget output"
    fi

    ID="$(grep -o 'ID [A-F0-9]*' "$TEMP" | cut -d " " -f 2)"
    if [ -z "$ID" ]; then
        die 4 "no ID in dget output"
    fi

    gpg --keyserver "pgp.mit.edu" --recv-keys "$ID"
    gpg --export "$ID" | apt-key add - || die 5 "gpg key import error"

    rm "$TEMP"
}

dch_msg()
{
    if [ -z "$SPECIAL_BACKPORT" ]; then
        dch --local "$BPOREV" --distribution "${CURRENTSUITE}-backports" "Rebuilt for ${CURRENTSUITE}."
    else
        msg "Please enter special backport instructions in the editor"
        sleep 3
        dch --local "$BPOREV" --distribution "${CURRENTSUITE}-backports"
    fi
}

# Build packages as a user (tests won't fail)
if [[ $EUID -ne 0 ]]; then
    die 1 "not recommended to run debackport with root privileges!"
fi

TEMP="$(mktemp)"
if [ -n "$SHORTBUILD" ]; then
    SHORTBUILD="yes"
fi

# Check for necessary packages
which make rmadison dget lintian &>/dev/null \
    || die 99 "apt-get install -y build-essential devscripts lintian dpkg-sig reprepro"

# Get current Debian release
CURRENTSUITE="$(lsb_release -s --codename)"
if [ -z "$CURRENTSUITE" ]; then
    die 9 "cannot detect current suite"
fi

# Get package name from parent dir's name
msg "check pkg"
if [ -z "$PKG" ]; then
    PKG="$(basename "$PWD")"
fi

if [ "$(uname -m)" == x86_64 ]; then
    ARCH="amd64"
else
    ARCH="i386"
fi

AVAILABLE="$(rmadison --architecture="$ARCH" --suite="$SUITE" "$PKG")"

if [ -z "$AVAILABLE" ]; then
    AVAILABLE="$(rmadison --suite="$SUITE" "$PKG")"
fi

if [ -z "$AVAILABLE" ]; then
    die 1 "not found in ${SUITE}"
fi
ok_msg "Source package: $AVAILABLE"

msg "Download sources"
DSCURL="$(wget -qO- "https://packages.debian.org/${SUITE}/${PKG}" | grep -o 'http.*\.dsc">\[' | cut -d '"' -f1)"
if [ -z "$DSCURL" ]; then
    die 2 "no .dsc"
fi

if ! dget ${ALLOW_UNAUTH} -x "$DSCURL" 2> "$TEMP"; then
    get_key
fi
# Manual unpack:  dpkg-source -x *.dsc

msg "Find and Install missing build dependencies"
SOURCES="$(grep -m 1 '^Source: ' ./*.dsc | cut -d " " -f 2)"

if [ -z "$SOURCES" ] || [ "$(wc -l <<< "$SOURCES")" -gt 1 ]; then
    ls -1 -d ./*/
    read -r -p "Please enter source package name: " SOURCES
fi
DIR="$(find . -maxdepth 1 -type d -iname "${SOURCES}-*" | head -n 1)"
if [ ! -d "$DIR" ]; then
    die 8 "no source dir: '$DIR'"
fi

if ! pushd "$DIR"; then
    die 9 "cannot change to '$DIR'"
fi

if ! dpkg-checkbuilddeps; then
    msg "Please install missing build dependencies!"
    /bin/bash
fi

msg "Indicate backport revision number in the changelog"
if ! dch_msg; then
    die 20 "Writing to changelog failed"
fi

if [ -z "$SHORTBUILD" ]; then
    msg "Test if we can successfully build the package"
    fakeroot debian/rules binary || die 10 "fakeroot build failed"

    popd || die 21 "Can't popd"

    msg "Clear fakeroot build and unpack sources again"
    rm -r -f "$DIR"
    dget ${ALLOW_UNAUTH} -x "$DSCURL"

    pushd "$DIR" || die 22 "Can't pushd"

    dpkg-checkbuilddeps || die 11 "still dependencies not fullfilled"
    dch_msg
else
    msg "Doing shortbuild!"
fi

msg "Build binary packages properly, without GPG signing them"
if ! dpkg-buildpackage -b -us -uc; then
    die 12 "build failed"
fi

popd || die 23 "Can't popd at the end"

ok_msg "Packages are ready."

while IFS="" read -r -d $'\0' PKG; do
    ls --color=always -1 "$PKG"
    lintian --info --display-info --display-experimental --pedantic --show-overrides "$PKG"
done < <(find . -name "*.deb" -print0)

echo
# Packaging GPG key
echo "dpkg-sig -k 451A4FBA --sign builder *.deb"
echo "cd /var/www/mirror/server/debian"
echo "reprepro remove ${CURRENTSUITE} ${PKG}"
echo "reprepro includedeb ${CURRENTSUITE} /var/www/mirror/debs/*.deb"
echo "make-index.sh"
