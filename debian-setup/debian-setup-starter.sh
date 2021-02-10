#!/bin/bash
#
# Start debian-setup.sh remotely.
#
# VERSION       :0.3.0
#
# - Domain registrar
# - DNS provider
# - Server provider (e.g. UpCloud)
# - SSL certificate provider (HTTPS)
# - CDN provider (static files)
# - Transactional email provider
# - Storage provider (server backup)
#
# 1. Aquire settings: webmaster@, hostname, networking, DNS resolvers, NTP servers, custom kernel, user names, SSH keys
# 2. Set up DNS resource records: PTR/IPv4 PTR/IPv6, A, AAAA, MX
# 3. PuTTY session: Connection/Data: viktor, xterm-256color; Connection/SSH/Auth: [ ] keyboard-interactive
# 4. Set up inbound ESP and bounce notification

SERVER_IP=94.237.80.0
SERVER_CONFIGURATION=./server.yml

ssh()
{
    /usr/bin/ssh -p 22 root@${SERVER_IP} "$@"
}

# Copy configuration file
test -r "$SERVER_CONFIGURATION" || exit 10
ssh -- bash -c "cat >/root/server.yml" <"$SERVER_CONFIGURATION" || exit 11


# Save script for Session #1
ssh -- bash -c "cat >/root/debian-setup-starter1.sh; chmod +x /root/debian-setup-starter1.sh" <<"EOT"
set -e
export LC_ALL="C.UTF-8"
SELF="$(realpath "${BASH_SOURCE[0]}")"
cd /root/

wget -O- https://github.com/szepeviktor/debian-server-tools/archive/master.tar.gz|tar xz
cd debian-server-tools-master/debian-setup/

# Skip missing DNS records
#sed -e 's|set -e -x|set +e -x|' -i ./packages/hostname
#echo "true" >>./packages/hostname

lsblk -f
tune2fs -L "debian-root" /dev/vda1

##script --timing=../debian-setup.time ../debian-setup.script
./debian-setup.sh
rm -v "$SELF"
EOT


# Save script for Session #2
ssh -- bash -c "cat >/root/debian-setup-starter2.sh; chmod +x /root/debian-setup-starter2.sh" <<"EOT"
set -e
export LC_ALL=C.UTF-8
SELF="$(realpath "${BASH_SOURCE[0]}")"
cd /root/debian-server-tools-master/debian-setup/

# @FIXME
export MONIT_EXCLUDED_PACKAGES=apache2:php5-fpm:php7.0-fpm:php7.1-fpm:php7.2-fpm:php7.3-fpm:php7.4-fpm
##script --timing=../debian-setup2.time ../debian-setup2.script
./debian-setup2.sh
rm -v "$SELF"
EOT


# Start Session #1
ssh -t -- /root/debian-setup-starter1.sh || exit 12

# Instructions for Session #2
echo "Log in as the first user on the specified SSH port and issue: sudo su -"
echo "Then as root issue: ./debian-setup-starter2.sh"
