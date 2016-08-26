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
# - View Network Graph v4/v6 http://bgp.he.net/
# - Aquire settings (custom kernel, user names, SSH keys, hostname, networking, resolvers, NTP servers)
# - Set up DNS (PTR, A, MX)
# - Make up /root/server.yml from /server.yml and from /debian-setup/providers/*.yml

export IMAGE_ARCH="amd64"
export IMAGE_MACHINE="x86_64"
export IMAGE_ID="Debian"
export IMAGE_CODENAME="jessie"
export WITHOUT_SYSTEMD="yes"

export SETUP_PACKAGES="lsb-release ca-certificates wget debian-archive-keyring apt apt-utils"
#:ubuntu
#export SETUP_PACKAGES="lsb-release ca-certificates wget ubuntu-keyring apt apt-utils"
export SETUP_APTSOURCES_URL_PREFIX="https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources"
export SETUP_APTSOURCESLIST_URL="${SETUP_APTSOURCES_URL_PREFIX}/${IMAGE_CODENAME}-azure.list"
#export SETUP_SOURCESLIST_URL="${SETUP_APTSOURCES_URL_PREFIX}/${IMAGE_CODENAME}-cloudfront.list"
#export SETUP_SOURCESLIST_URL="${SETUP_APTSOURCES_URL_PREFIX}/${IMAGE_CODENAME}-hu.list"

export SETUP_SHYAML_URL="https://github.com/0k/shyaml/raw/master/shyaml"

set -e -x

. debian-setup-functions

# Am I root?
[ "$(id -u)" == 0 ]

# Necessary packages
IS_FUNCTIONAL="yes"
[ -n "$(which dpkg-query)" ]
for PKG in ${SETUP_PACKAGES}; do
    if Is_installed "$PKG"; then
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
if Is_installed "libgnutls26"; then
    apt-get purge -y libboost-iostreams1.49.0 libdb5.1 libgcrypt11 libgnutls26 \
        libprocps0 libtasn1-3 libudev0 python2.6 python2.6-minimal
fi
# Remove ClamAV data
rm -rf /var/lib/clamav /var/log/clamav || true

# Packages used during setup
apt-get install -y ssh sudo apt-transport-https virt-what python-yaml
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
