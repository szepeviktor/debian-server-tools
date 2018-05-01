#!/bin/bash
#
# - Domain registrar
# - DNS provider
# - Server provider (e.g. UpCloud)
# - SSL certificate provider (HTTPS)
# - CDN provider (static files)
# - Transactional email provider
# - Storage provider (server backup)
#
# * Aquire settings: webmaster@, hostname, networking, DNS resolvers, NTP servers, custom kernel, user names, SSH keys
# * Set up DNS resource records: PTR/IPv4 PTR/IPv6, A, AAAA, MX
# * PuTTY session: Connection/Data: viktor, xterm-256color; Connection/SSH/Auth: [ ] keyboard-interactive
# * Set up inbound ESP and bounce notification

SERVER_IP=94.237.80.0
SERVER_CONFIGURATION=./server.yml

ssh()
{
    /usr/bin/ssh -p 22 root@${SERVER_IP} "$@"
}

# Copy configuration file
test -r ${SERVER_CONFIGURATION} || exit 100
ssh "cat > /root/server.yml" < ${SERVER_CONFIGURATION}

# Save script for Session #2
ssh "cat > /root/debian-setup-starter2.sh; chmod +x /root/debian-setup-starter2.sh" <<"EOT"
export LC_ALL=C.UTF-8
cd /root/debian-server-tools-master/

# MySQL 5.7
#printf 'Package: *\nPin: release a=unstable\nPin-Priority: 100\n' > /etc/apt/preferences.d/sid.pref
#sed -e 's|Pkg_install_quiet mariadb-server mariadb-client|apt-get install -qq mysql-common/sid mysql-server-5.7/sid|' -i ./debian-setup/mariadb-server
#sed -e 's|Pkg_install_quiet percona-xtrabackup|&-24|' -i ./debian-setup/mariadb-server

# @FIXME
export MONIT_EXCLUDED_PACKAGES=apache2:php5-fpm:php7.0-fpm:php7.1-fpm:php7.2-fpm
##script --timing=../debian-setup2.time ../debian-setup2.script
./debian-setup2.sh
EOT

# Execute Session #1
ssh <<"EOT"
export LC_ALL=C.UTF-8
cd /root/

wget -O- https://github.com/szepeviktor/debian-server-tools/archive/master.tar.gz|tar xz
cd debian-server-tools-master/

# Skip missing DNS records
#sed -e 's|set -e -x|set +e -x|' -i ./debian-setup/hostname

lsblk -f
tune2fs -L "debian-root" /dev/vda1

##script --timing=../debian-setup.time ../debian-setup.script
./debian-setup.sh
EOT
