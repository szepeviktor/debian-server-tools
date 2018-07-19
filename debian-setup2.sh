#!/bin/bash
#
# Continue Debian stretch setup on a virtual server.
#
# VERSION       :2.1.2
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
. debian-setup-functions.inc.sh

VIRT="$(Data get-value virtualization)"
export VIRT

IP="$(ifconfig | sed -n -e '0,/^\s*inet \(addr:\)\?\([0-9\.]\+\)\b.*$/s//\2/p')"
export IP

# _check-system needs most
debian-setup/most

# Manual checks
debian-setup/_check-system

# Basic packages
Pkg_install_quiet \
    localepurge unattended-upgrades apt-listchanges debsums \
    ncurses-term mc most less time moreutils unzip \
    logtail apg bc dos2unix ccze colordiff sipcalc jq \
    net-tools whois ntpdate ipset netcat-openbsd lftp s-nail \
    gcc libc6-dev make strace \
    unscd mtr-tiny cruft bash-completion htop mmdb-bin

# Provide mail command
debian-setup/s-nail

# From backports
# List available backports: apt-get upgrade -t stretch-backports
# @nonDebian
Pkg_install_quiet \
    -t stretch-backports needrestart geoipupdate git goaccess
# Also in debian-setup/fail2ban

# From testing
debian-setup/ca-certificates

# From custom repos
debian-setup/ipset-persistent

# Provider packages
if [ -n "$(Data get-value provider-package "")" ]; then
    # shellcheck disable=SC2046
    Pkg_install_quiet $(Data get-values provider-package)
fi

# Restore original sudoers file
debian-setup/sudo

debian-setup/locales

# tzdata first as it may modify system time
debian-setup/tzdata
debian-setup/rsyslog

debian-setup/localepurge
debian-setup/unattended-upgrades

# Custom APT repository script
Dinstall package/apt-add-repo.sh

# @FIXME
#debian-setup/ifupdown

debian-setup/_resolv_conf

# Micro Name Service Caching
debian-setup/unscd

debian-setup/kmod
debian-setup/procps

debian-setup/mount

debian-setup/initscripts

# IRQ balance
CPU_COUNT="$(grep -c "^processor" /proc/cpuinfo)"
if [ "$CPU_COUNT" -gt 1 ]; then
    # Stable has a bug, it exits
    Pkg_install_quiet irqbalance
    cat /proc/interrupts
elif Is_installed "irqbalance"; then
    apt-get purge -qq irqbalance
fi

# Time synchronization
debian-setup/util-linux
# @TODO
# if grep "kvm-clock" /sys/devices/system/clocksource/clocksource0/current_clocksource \
#     || dmesg | grep -w "kvm-clock"; then
#     # Display clock sources
#     cat /sys/devices/system/clocksource/clocksource0/available_clocksource
#     echo "https://s19n.net/articles/2011/kvm_clock.html"
# fi
if [ "$VIRT" == "kvm" ] && ! Is_installed systemd; then
    debian-setup/chrony
fi
# Monitor clock without monit
#     Dinstall monitoring/monit/services/ntpdate_script
#     echo -e '#!/bin/bash\n/usr/local/bin/ntp-alert.sh' > /etc/cron.daily/ntp-alert1
#     chmod +x /etc/cron.daily/ntp-alert1

# Entropy
if Is_installed "rng-tools"; then
    # VirtIO RNG on KVM
    [ -c /dev/hwrng ]
    cat /sys/devices/virtual/misc/hw_random/rng_{available,current}
else
    # Software based entropy source
    cat /proc/sys/kernel/random/entropy_avail
    Pkg_install_quiet haveged
    cat /proc/sys/kernel/random/entropy_avail
fi

# @TODO
#if [ "$VIRT" == kvm ]; then
#    debian-setup/_virt-kvm
#fi
if [ "$VIRT" == xen ]; then
    debian-setup/_virt-xen
fi
if [ "$VIRT" == vmware ]; then
    debian-setup/_virt-vmware
fi

if [ -n "$(Data get-value software.aruba-arping "")" ]; then
    Dinstall monitoring/aruba-arping.sh
fi

# Extra packages
if [ -n "$(Data get-value package.apt.extra "")" ]; then
    # shellcheck disable=SC2046
    Pkg_install_quiet $(Data get-values package.apt.extra)
fi

debian-setup/cron

debian-setup/debsums

debian-setup/openssh-client

debian-setup/mc

debian-setup/iptables

# After debian-setup/iptables
debian-setup/fail2ban

#debian-setup/_cert-szepenet

#debian-setup/proftpd-basic

# Tools (courier uses catconf)
for TOOL in catconf cnet doc hosthost hostinfo ip.sh lsrev msec reboot revip \
    sortip swap-usage.sh u udrush uwp whichdo whoistop; do
    Dinstall "tools/${TOOL}"
done

# Courier MTA - deliver all messages to a smarthost
mail/courier-mta-satellite-system.sh

if Is_installed "msmtp-mta"; then
    debian-setup/msmtp-mta
fi
#if Is_installed "nullmailer"; then
#    debian-setup/nullmailer
#fi

# init-alert (after MTA)
# @nonDebian
Pkg_install_quiet init-alert

# Apache 2.4
webserver/apache-httpd.sh
Dinstall webserver/apache-resolve-hostnames.sh
if Is_installed "mod-pagespeed-stable"; then
    debian-setup/mod-pagespeed-stable
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
fi
export PHP
webserver/php-fpm.sh

# Package managers
debian-setup/_package-python-pip
# Needs PHP-CLI
debian-setup/_package-php-composer
# Node.js (from package.apt.extra)
# @nonDebian
if Is_installed "nodejs"; then
    debian-setup/nodejs
fi

# Webserver reload
Dinstall webserver/webrestart.sh
# Redis server and PHP extension
debian-setup/redis-server
webserver/php-redis.sh
if Data get-values-0 package.apt.sources | grep -z -F -x 'mysql-5.7'; then
    # MySQL 5.7 from Debian sid
    debian-setup/mariadb-server
elif Data get-values-0 package.apt.sources | grep -q -z -F -x 'percona' \
    && [ -n "$(Data get-value package.apt.extra "")" ] \
    && Data get-values-0 package.apt.extra | grep -z -F -x 'percona-server-server-5.7'; then
    # Percona Server 5.7
    debian-setup/percona-server-server-5.7
elif Data get-values-0 package.apt.sources | grep -z -F -x 'oracle-mysql-server'; then
    # Oracle MySQL 5.7
    debian-setup/mysql-community-server
else
    # MariaDB
    debian-setup/mariadb-server
fi

# Add the development website, needs composer
webserver/add-prg-site-auto.sh

# apache-default, apache-combined and apache-instant Fail2ban jails are enabled by default
service fail2ban restart

# Backup
Pkg_install_quiet debconf-utils rsync mariadb-client
# percona-xtrabackup is installed in debian-setup/mariadb,mysql
# @nonDebian
Pkg_install_quiet s3ql
# Disable Apache configuration from javascript-common
if hash a2disconf 2> /dev/null; then
    a2disconf javascript-common
fi

# CLI tools
debian-setup/php-wpcli
# WordPress cron
Dinstall webserver/wp-cron-cli.sh
debian-setup/php-cachetool
#debian-setup/php-drush

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
debian-setup/libpam-modules

# @TODO
# Munin - network-wide graphing
#monitoring/munin/munin-debian-setup.sh

# Clean up
apt-get autoremove --purge -y
apt-get clean

# Throttle automatic package downloads
echo -e 'Acquire::Queue-mode "access";\nAcquire::http::Dl-Limit "1000";' > /etc/apt/apt.conf.d/76throttle-download

# etckeeper at last
debian-setup/etckeeper

# Manual inspection of emails
find /var/mail/ -type f -exec grep -H '^' "{}" ";"

# Manual inspection of old configuration files
echo "@TODO - Old configs"
find /etc/ -type f -iname "*old" -or -iname "*dist" | paste -s -d " "

# Clear Bash history
history -c

set +x

# @TODO Automate these
cat <<"EOT"
# TODO - iptables-save
iptables-save | grep -E -v '(:|\s)f2b-' | sed -e 's| \[[0-9]*:[0-9]*\]$| [0:0]|' > /etc/iptables/rules.v4
# TODO - hosts
editor /etc/hosts
# TODO - users
adduser USER
# TODO - server backup
./install.sh backup/system-backup.sh
# TODO - monit/apache+php
monitoring/monit/monit-debian-setup.sh
# TODO - Monitoring
https://github.com/szepeviktor/debian-server-tools/blob/master/monitoring/README.md

EOT

echo "OK. (exit from script command now)"
