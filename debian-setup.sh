#!/bin/bash
#
# Debian jessie setup on a virtual server.
#
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# AUTORUN       :wget -O ds.sh http://git.io/vtcLq && . ds.sh

# Steps
#
# - aquire settings (custom kernel, user names, SSH keys, hostname, networking, resolvers, NTP servers)
# - set up DNS (PTR, A, MX)

export IMAGE_ARCH="amd64"
export IMAGE_MACHINE="x86_64"
export IMAGE_ID="Debian"
export IMAGE_CODENAME="jessie"

export SETUP_APTSOURCES_URL_PREFIX="https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources"
export SETUP_APTSOURCESLIST_URL="${SETUP_APTSOURCES_URL_PREFIX}/${IMAGE_CODENAME}-azure.list"
#export SETUP_SOURCESLIST_URL="${SETUP_APTSOURCES_URL_PREFIX}/${IMAGE_CODENAME}-cloudfront.list"
#export SETUP_SOURCESLIST_URL="${SETUP_APTSOURCES_URL_PREFIX}/${IMAGE_CODENAME}-hu.list"
export SETUP_PACKAGES="lsb-release ca-certificates wget debian-archive-keyring apt apt-utils"
export SETUP_SHYAML_URL="https://github.com/0k/shyaml/raw/master/shyaml"
#:ubuntu
#export SETUP_PACKAGES="lsb-release ca-certificates wget ubuntu-keyring apt apt-utils"

export WITHOUT_SYSTEMD="yes"

Error() {
    echo "ERROR: $(tput bold;tput setaf 7;tput setab 1)${*}$(tput sgr0)" 1>&2
}

# Download architecture-independent packages
Getpkg() {
    local P="$1"
    local R="${2-sid}"
    local WEB="https://packages.debian.org/${R}/all/${P}/download"
    local URL

    URL="$(wget -q -O- "$WEB" | grep -o '[^"]\+ftp.de.debian.org/debian[^"]\+\.deb')"

    [ -z "$URL" ] && return 1

    wget -q -O "${P}.deb" "$URL"
    dpkg -i "${P}.deb"
    echo "Ret=$?"
}

Data() {
    shyaml "$@" < /root/server.yml
}
export -f Data

set -e -x

# Am I root?
[ "$(id -u)" == 0 ]

# Necessary packages
IS_FUNCTIONAL="yes"
[ -n "$(which dpkg-query)" ]
for PKG in ${SETUP_PACKAGES}; do
    if [ "$(dpkg-query --showformat="\${Status}" --show "${PKG}" 2> /dev/null)" != "install ok installed" ]; then
        IS_FUNCTIONAL="no"
        break
    fi
done
if [ "$IS_FUNCTIONAL" != "yes" ]; then
    apt-get update -qq || true
    # shellcheck disable=SC2086
    apt-get install -y --force-yes ${SETUP_PACKAGES} || true
    # These packages should be auto installed
    apt-mark auto lsb-release ca-certificates || true
fi

# Package sources
debian-setup/apt

# OS check
debian-setup/base-files

# OS image normalization (does dist-upgrade)
apt-get install -y aptitude
./debian-image-normalize.sh

# Remove wheezy packages
apt-get purge -y libboost-iostreams1.49.0 libdb5.1 libgcrypt11 libgnutls26 \
    libprocps0 libtasn1-3 libudev0 python2.6 python2.6-minimal

# Packages used during setup
apt-get install -y ssh sudo apt-transport-https python-yaml
# Install SHYAML
wget -nv -O /usr/local/bin/shyaml "$SETUP_SHYAML_URL"
chmod +x /usr/local/bin/shyaml

# APT repositories
for REPO in $(Data get-values apt.repository); do
    wget -nv -O "/etc/apt/sources.list.d/${REPO}.list" "${SETUP_APTSOURCES_URL_PREFIX}/${REPO}.list"
done
# Import signing keys
eval "$(grep -h -A 5 "^deb " /etc/apt/sources.list.d/*.list | grep "^#K: " | cut -d " " -f 2-)"
# Get package lists
apt-get update -qq

# Provider packages
if [ -n "$(Data get-value provider-package)" ]; then
    apt-get install -y $(Data get-values provider-package)
fi

# Virtualization environment
debian-setup/virt-what

debian-setup/hostname
debian-setup/login
debian-setup/dash
debian-setup/readline-common

# Root user and first user
debian-setup/adduser
# After adduser
debian-setup/openssh-server

# Optionally switch to SysVinit
debian-setup/systemd

# Log in on a new terminal and log out here
exit 0
