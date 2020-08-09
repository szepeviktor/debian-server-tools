#!/bin/bash
#
# Continue Debian buster setup on a virtual server.
#
# VERSION       :3.0.0
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# CI            :shellcheck -x debian-setup2.sh
# CONFIG        :/root/server.yml

# Advise
#
# Prepare two terminals.

declare -i CPU_COUNT

set -e -x

if [ ! -t 0 ]; then
    echo "Some commands still need a terminal." 1>&2
    exit 10
fi

# shellcheck disable=SC1091
source debian-setup-functions.inc.sh

IP="$(hostname --all-ip-addresses | cut -d " " -f 1)"
export IP

VIRT="$(Data get-value virtualization)"
export VIRT

# _check-system needs most
packages/most

# Manual checks
packages/_check-system

# Basic packages
Pkg_install_quiet \
    localepurge unattended-upgrades apt-listchanges debsums \
    ncurses-term mc most less time moreutils unzip \
    logtail apg bc dos2unix ccze colordiff sipcalc jq \
    net-tools dnsutils ntpdate ipset netcat-openbsd lftp s-nail \
    gcc g++ libc6-dev make strace \
    unscd cruft bash-completion htop mmdb-bin geoipupdate \
    init-system-helpers needrestart git mtr-tiny whois openssl

# Provide mail command
packages/s-nail

# @nonDebian
packages/goaccess

# From backports
# List available backports: apt-get upgrade -t buster-backports
# @nonDebian
##Pkg_install_quiet -t buster-backports

packages/needrestart

packages/ca-certificates

packages/ipset-persistent

# Provider packages
if [ -n "$(Data get-value provider-package "")" ]; then
    # shellcheck disable=SC2046
    Pkg_install_quiet $(Data get-values provider-package)
fi

# Restore original sudoers file
packages/sudo

packages/locales

# tzdata first as it may modify system time
packages/tzdata
packages/rsyslog

packages/localepurge
packages/unattended-upgrades

# Custom APT repository script
Dinstall package/apt-add-repo.sh

# @FIXME
#packages/ifupdown

packages/_resolv_conf

# Micro Name Service Caching
packages/unscd

packages/kmod
packages/procps

packages/mount

packages/initscripts

# IRQ balance
CPU_COUNT="$(grep -c "^processor" /proc/cpuinfo)"
if [ "$CPU_COUNT" -gt 1 ]; then
    Pkg_install_quiet irqbalance
    cat /proc/interrupts
elif Is_installed "irqbalance"; then
    apt-get purge -qq irqbalance
fi

# Time synchronization
packages/util-linux
# @TODO
# if grep -F 'kvm-clock' /sys/devices/system/clocksource/clocksource0/current_clocksource \
#     || dmesg | grep -F -w 'kvm-clock'; then
#     # Display clock sources
#     cat /sys/devices/system/clocksource/clocksource0/available_clocksource
#     echo "https://s19n.net/articles/2011/kvm_clock.html"
# fi
if [ "$VIRT" == kvm ] && ! Is_installed systemd; then
    packages/chrony
fi
# Monitor clock without monit
#     Dinstall monitoring/monit/services/ntpdate_script
#     echo -e '#!/bin/bash\n/usr/local/bin/ntp-alert.sh' >/etc/cron.daily/ntp-alert1
#     chmod +x /etc/cron.daily/ntp-alert1

# Entropy
if Is_installed "rng-tools"; then
    # VirtIO RNG on KVM
    test -c /dev/hwrng
    cat /sys/devices/virtual/misc/hw_random/rng_{available,current}
else
    # Software based entropy source
    cat /proc/sys/kernel/random/entropy_avail
    Pkg_install_quiet haveged
    cat /proc/sys/kernel/random/entropy_avail
fi

# @TODO
#if [ "$VIRT" == kvm ]; then
#    packages/_virt-kvm
#fi
if [ "$VIRT" == xen ]; then
    packages/_virt-xen
fi
if [ "$VIRT" == vmware ]; then
    packages/_virt-vmware
fi

if [ -n "$(Data get-value software.aruba-arping "")" ]; then
    Dinstall monitoring/aruba-arping.sh
fi

# Extra packages
if [ -n "$(Data get-value package.apt.extra "")" ]; then
    # shellcheck disable=SC2046
    Pkg_install_quiet $(Data get-values package.apt.extra)
fi

packages/cron

packages/debsums

packages/openssh-client

packages/mc

packages/iptables

# After packages/iptables
packages/fail2ban

#packages/_cert-szepenet

# FTP protocol is deprecated.
#packages/proftpd-basic

# Tools (courier uses catconf)
for TOOL in catconf cnet doc hosthost hostinfo ip.sh lsrev msec reboot revip \
    sortip swap-usage.sh u udrush uwp whichdo whoistop; do
    Dinstall "tools/${TOOL}"
done

# Courier MTA - deliver all messages to a smarthost
../mail/courier-mta-satellite-system.sh

if Is_installed "msmtp-mta"; then
    packages/msmtp-mta
fi
#if Is_installed "nullmailer"; then
#    packages/nullmailer
#fi

# init-alert (after MTA)
# @nonDebian
Pkg_install_quiet init-alert

# Apache 2.4
../webserver/apache-httpd.sh
Dinstall webserver/apache-resolve-hostnames.sh
if Is_installed "mod-pagespeed-stable"; then
    packages/mod-pagespeed-stable
fi

# PHP-FPM
if Data get-values-0 package.apt.extra | grep -z -F -x 'php5-fpm' \
    || Data get-values-0 package.apt.extra | grep -z -F -x 'php5.6-fpm'; then
    PHP="5.6"
elif Data get-values-0 package.apt.extra | grep -z -F -x 'php7.0-fpm'; then
    PHP="7.0"
elif Data get-values-0 package.apt.extra | grep -z -F -x 'php7.1-fpm'; then
    PHP="7.1"
elif Data get-values-0 package.apt.extra | grep -z -F -x 'php7.2-fpm'; then
    PHP="7.2"
elif Data get-values-0 package.apt.extra | grep -z -F -x 'php7.3-fpm'; then
    PHP="7.3"
elif Data get-values-0 package.apt.extra | grep -z -F -x 'php7.4-fpm'; then
    PHP="7.4"
fi
if [ -n "$PHP" ]; then
    export PHP
    ../webserver/php-fpm.sh
    # Needs PHP-CLI
    packages/_package-php-composer
    packages/_package-php-phive
    ../webserver/php-redis.sh
    # CLI tools
    packages/php-wpcli
    # WordPress cron
    Dinstall webserver/wp-install/wp-cron-cli.sh
    packages/php-cachetool
    ##packages/php-drush
fi

# Package managers
packages/_package-python-pip
Dinstall package/python-add-opt-package.sh
# Node.js (from package.apt.extra)
# https://nodejs.org/en/download/releases/
# @nonDebian
if Is_installed "nodejs"; then
    packages/nodejs
fi

# Webserver reload
Dinstall webserver/webrestart.sh

# Redis server
packages/redis-server

if Data get-values-0 package.apt.sources | grep -z -F -x 'mysql-5.7'; then
    # MySQL 5.7 from Debian sid
    packages/mariadb-server
elif Data get-values-0 package.apt.sources | grep -q -z -F -x 'percona' \
    && [ -n "$(Data get-value package.apt.extra "")" ] \
    && Data get-values-0 package.apt.extra | grep -z -F -x 'percona-server-server-5.7'; then
    # Percona Server 5.7
    packages/percona-server-server-5.7
elif Data get-values-0 package.apt.sources | grep -z -F -x 'oracle-mysql-server'; then
    # Oracle MySQL 5.7
    packages/mysql-community-server
else
    # MariaDB
    packages/mariadb-server
fi

# Add the development website, needs composer
##webserver/add-prg-site-auto.sh

# apache-default, apache-combined and apache-instant Fail2ban jails are enabled by default
service fail2ban restart

# Backup
Pkg_install_quiet debconf-utils rsync mariadb-client
# percona-xtrabackup is installed in packages/mariadb,mysql
# @nonDebian
Pkg_install_quiet -t buster-backports s3ql

# Monit - monitoring
# @FIXME Needs a production website for apache2 and php-fpm
# @FIXME Defaults file editor
# @FIXME Depends on repo
(
    cd /usr/local/src/debian-server-tools/monitoring/monit/
    install --mode=0640 -D -t /etc/monit monit.defaults
    editor /etc/monit/monit.defaults
    ./monit-debian-setup.sh
)

# After monit
packages/libpam-modules

# Disable Apache configuration from javascript-common
if hash a2disconf 2>/dev/null && [ -f /etc/apache2/conf-available/javascript-common.conf ]; then
    a2disconf javascript-common
fi

# @TODO
# Munin - network-wide graphing
#monitoring/munin/munin-debian-setup.sh

# Clean up
apt-get autoremove --purge -y
apt-get clean

# Throttle automatic package downloads
echo -e 'Acquire::Queue-mode "access";\nAcquire::http::Dl-Limit "1000";' >/etc/apt/apt.conf.d/76throttle-download

# etckeeper at last
packages/etckeeper

# Remove old configuration files
find /etc/ -type f "(" -iname "*old" -or -iname "*dist" ")" -print -delete

# List of emails
find /var/mail/ -type f

# Clear Bash history
history -c

set +x

# @TODO Automate these
cat <<"EOT"
# TODO - hosts
editor /etc/hosts
# TODO - users
adduser USER
# TODO - server backup
./install.sh backup/system-backup.sh
# TODO - monit/apache+php
lspci -n >lspci.out
monitoring/monit/monit-debian-setup.sh
# TODO - Monitoring
open https://github.com/szepeviktor/debian-server-tools/blob/master/monitoring/README.md

EOT

echo "OK. (exit from script command now)"
