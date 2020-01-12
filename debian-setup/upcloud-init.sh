#!/bin/bash
#
# Prepare UpCloud server with docker and pip.
#
# Initialization script:  https://github.com/szepeviktor/debian-server-tools/raw/master/debian-setup/upcloud-init.sh
# Follow log:  tail -f /var/log/upcloud_userdata.log

# http://deb.debian.org/debian/pool/contrib/g/geoipupdate/
GEOIPUPDATE_VERSION="3.1.1-1"
DEBIAN_CODENAME="stretch"

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"

Auto_country() {
    apt-get clean
    apt-get update
    apt-get install -qq mmdb-bin netselect-apt
    wget -nv "http://deb.debian.org/debian/pool/contrib/g/geoipupdate/geoipupdate_${GEOIPUPDATE_VERSION}_amd64.deb"
    dpkg -i geoipupdate_*_amd64.deb
    geoipupdate

    IP="$(hostname --all-ip-addresses | cut -d " " -f 1)"
    test -n "$IP"
    COUNTRY="$(mmdblookup --file /var/lib/GeoIP/GeoLite2-Country.mmdb --ip "$IP" registered_country iso_code | sed -n -e '0,/.*"\([A-Z]\+\)".*/s//\1/p')" #'
    test -n "$COUNTRY"
    netselect-apt -c "$COUNTRY" stable
    MIRROR="$(sed -n -e '0,/^deb \(http\S\+\) .*$/s//\1/p' sources.list)"
    test -n "$MIRROR"
    rm -f geoipupdate_*_amd64.deb sources.list

    wget -nv -O- "https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources/sources.list" \
        | sed -e "s|@@MIRROR@@|${MIRROR}|" >/etc/apt/sources.list
}

set -e -x

# Create temporary files in /tmp
test -d /tmp && cd /tmp/

# Output may end up in a log file
echo 'Dpkg::Use-Pty "0";' >/etc/apt/apt.conf.d/00usepty

# LeaseWeb sources
wget -nv -O /etc/apt/sources.list \
    "https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources/${DEBIAN_CODENAME}-for-upcloud.list"

# Update Debian
apt-get clean -q
apt-get update -q
# Pending kernel update prevents docker-engine to run without reboot
apt-mark hold linux-image-amd64 'linux-image-[0-9].*-amd64'
apt-get dist-upgrade -qq

# docker
apt-get install -qq dirmngr apt-transport-https
wget -qO- https://download.docker.com/linux/debian/gpg | apt-key add -
echo "deb https://download.docker.com/linux/debian ${DEBIAN_CODENAME} stable" \
    >/etc/apt/sources.list.d/docker.list
apt-get update -q
# https://forums.docker.com/t/62505 ExecStart=/usr/bin/dockerd -H unix://
apt-get install -qq docker-ce || apt-get install -qq -f
systemctl status docker.service
docker version

# pip
apt-get install -qq python3-dev
wget -nv "https://bootstrap.pypa.io/get-pip.py"
python3 get-pip.py
rm -f get-pip.py
pip3 --version

rm -f /etc/apt/apt.conf.d/00usepty

echo "OK."
