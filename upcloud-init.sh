#!/bin/bash
#
# Prepare UpCloud server with docker and pip.
#
# Initialization script: https://github.com/szepeviktor/debian-server-tools/raw/master/upcloud-init.sh
# Follow log: tail -f /var/log/upcloud_userdata.log

# http://deb.debian.org/debian/pool/contrib/g/geoip-database-contrib/
GEOIP_VERSION="1.19"
DEBIAN_CODENAME="jessie"

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"

Auto_country() {
    apt-get clean
    apt-get update
    apt-get install -qq geoip-bin netselect-apt
    wget -nv "http://deb.debian.org/debian/pool/contrib/g/geoip-database-contrib/geoip-database-contrib_${GEOIP_VERSION}_all.deb"
    dpkg -i geoip-database-contrib_*_all.deb

    IP="$(ifconfig|sed -n -e '0,/^\s*inet \(addr:\)\?\([0-9\.]\+\)\b.*$/s//\2/p')"
    test -n "$IP"
    COUNTRY="$(geoiplookup -f /usr/share/GeoIP/GeoIP.dat "$IP"|sed -ne 's|^GeoIP Country Edition: \(..\),.*$|\1|p')"
    test -n "$COUNTRY"
    netselect-apt -c "$COUNTRY" stable
    MIRROR="$(sed -ne '0,/^deb \(http\S\+\) .*$/s//\1/p' sources.list)"
    test -n "$MIRROR"
    rm -f geoip-database-contrib_*_all.deb sources.list

    wget -nv -O- "https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources/sources.list" \
        | sed -e "s|@@MIRROR@@|${MIRROR}|" > /etc/apt/sources.list
}

set -e -x

# Create temporary files in /tmp
[ -d /tmp ] && cd /tmp/

# Output may end up in a log file
echo 'Dpkg::Use-Pty "0";' > /etc/apt/apt.conf.d/00usepty

# LeaseWeb sources
wget -nv -O /etc/apt/sources.list \
    "https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources/${DEBIAN_CODENAME}-for-upcloud.list"

apt-get clean -q
apt-get update -q
# Prevent kernel update
#apt-mark hold linux-image-amd64 "linux-image-[0-9].*-amd64"
apt-get dist-upgrade -q -y

# docker
apt-get install -qq apt-transport-https
apt-key adv --keyserver "hkp://p80.pool.sks-keyservers.net:80" --recv-keys 2C52609D
echo "deb https://apt.dockerproject.org/repo debian-${DEBIAN_CODENAME} main" \
    > /etc/apt/sources.list.d/docker.list
apt-get update -q
apt-get install -qq docker-engine
docker version

# pip
apt-get install -qq python3-dev
wget -nv "https://bootstrap.pypa.io/get-pip.py"
python3 get-pip.py
rm -f get-pip.py
pip3 --version

rm -f /etc/apt/apt.conf.d/00usepty

echo "OK."
