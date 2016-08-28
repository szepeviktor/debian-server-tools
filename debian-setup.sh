#!/bin/bash
#
# Debian jessie setup on a virtual server.
#
# VERSION       :1.0.0
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# CI            :shellcheck
# CONFIG        :/root/server.yml

# Execution Steps
#
# 1. wget -O- https://github.com/szepeviktor/debian-server-tools/archive/master.tar.gz|tar xz
#    cd debian-server-tools-master/
# 2. Evaluate Network Graph v4 and v6 http://bgp.he.net/
# 3. Aquire settings (custom kernel, user names, SSH keys, hostname, networking, resolvers, NTP servers)
# 4. Make up /root/server.yml from /server.yml and from /debian-setup/providers/*.yml
# 5. Set up DNS (PTR, A, AAAA, MX)
# 6. Start!  ./debian-setup.sh
# @FIXME  export MONIT_EXCLUDED_PACKAGES=apache2:php5-fpm:php7.0-fpm
# 7. Consider creating a disk or vm template with isc-dhcp-client installed
# 8. Continue  ./debian-setup2.sh

# Features
#
# - YAML configuration file with provider profiles
# - OS image normalization
# - Optionally switch to SysVinit
# - Boot and Halt alert
# - UTC timezone
# - Micro Name Service Caching
# - IRQ balance
# - Time synchronization
# - Hardware TRNG or HAVEGE generator
# - Fail2ban and block dangerous networks
# - Monit monitoring
# - Courier MTA
# - System backup
# - Nice motd welcome
# - Package managers (composer, pip, npm)
# - 155 MB memory usage, 2 GB disk usage
#
# Webserver
#
# - Apache 2.4 latest with HTTP/2 and event MPM
# - PHP 5.6 or 7.0 through PHP-FPM
# - CLI tools
# - Redis in-memory cache
# - MariaDB 10

export IMAGE_ARCH="amd64"
export IMAGE_MACHINE="x86_64"
export IMAGE_ID="Debian"
export IMAGE_CODENAME="jessie"
export WITHOUT_SYSTEMD="yes"

export SETUP_PACKAGES="debian-archive-keyring lsb-release ca-certificates wget apt apt-utils"
#:ubuntu
#export SETUP_PACKAGES="ubuntu-keyring lsb-release ca-certificates wget apt apt-utils"
export SETUP_APTSOURCES_URL_PREFIX="https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources"
# Microsoft Azure Traffic Manager
export SETUP_APTSOURCESLIST_URL="${SETUP_APTSOURCES_URL_PREFIX}/${IMAGE_CODENAME}-azure.list"
# Amazon CloudFront
#export SETUP_SOURCESLIST_URL="${SETUP_APTSOURCES_URL_PREFIX}/${IMAGE_CODENAME}-cloudfront.list"
# Hungarian Debian mirror
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
    if ! Is_installed "$PKG"; then
        IS_FUNCTIONAL="no"
        break
    fi
done
if [ "$IS_FUNCTIONAL" != "yes" ]; then
    apt-get update -qq || true
    # shellcheck disable=SC2086
    apt-get install -y --force-yes ${SETUP_PACKAGES} || true
    # These packages should be auto-installed
    apt-mark auto lsb-release ca-certificates || true
fi

# Package sources
debian-setup/apt

# OS check
debian-setup/base-files

# OS image normalization (does dist-upgrade)
apt-get install -qq -y aptitude
./debian-image-normalize.sh

# Remove wheezy packages
if Is_installed "libgnutls26"; then
    apt-get purge -qq -y \
        libboost-iostreams1.49.0 libdb5.1 libgcrypt11 libgnutls26 \
        libprocps0 libtasn1-3 libudev0 python2.6 python2.6-minimal
fi
# Remove ClamAV data
rm -rf /var/lib/clamav /var/log/clamav || true

# Packages used during setup
apt-get install -qq -y ssh sudo apt-transport-https virt-what python-yaml
# Install SHYAML (config reader)
wget -nv -O /usr/local/bin/shyaml "$SETUP_SHYAML_URL"
chmod +x /usr/local/bin/shyaml

# Add APT repositories
for REPO in $(Data get-values apt.repository); do
    wget -nv -O "/etc/apt/sources.list.d/${REPO}.list" "${SETUP_APTSOURCES_URL_PREFIX}/${REPO}.list"
done
# Import signing keys
eval "$(grep -h -A 5 "^deb " /etc/apt/sources.list.d/*.list | grep "^#K: " | cut -d " " -f 2-)"
# Get package lists
apt-get update -qq

IP="$(ifconfig | sed -n -e '0,/^\s*inet addr:\([0-9\.]\+\)\b.*$/s//\1/p')"
export IP

# Virtualization environment
debian-setup/virt-what

debian-setup/hostname
debian-setup/login
debian-setup/readline-common
# Set Bash as default
debian-setup/dash

# Root user and first user
debian-setup/adduser
# After adduser
debian-setup/openssh-server

# Optionally (WITHOUT_SYSTEMD) switch to SysVinit
debian-setup/systemd

# Log in on a new terminal and log out here
exit 0
