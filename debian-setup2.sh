#!/bin/bash
#
# Continue Debian setup on a virtual server.
#

declare -i CPU_COUNT

set -e -x

. debian-setup-functions

VIRT="$(Data get-value virtualization)"
export VIRT

# Manual checks
debian-setup/_check-system

# Basic packages
DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
    ipset time netcat-openbsd lftp \
    ncurses-term bash-completion mc htop most less \
    localepurge unattended-upgrades apt-listchanges cruft debsums etckeeper \
    gcc libc6-dev make strace \
    moreutils logtail whois unzip heirloom-mailx \
    apg dos2unix ccze git colordiff mtr-tiny ntpdate \

# Backports
apt-get install -t jessie-backports -y needrestart unscd
# sid
debian-setup/ca-certificates
# From custom repos
apt-get install -y goaccess ipset-persistent

# Provider packages
if [ -n "$(Data get-value provider-package)" ]; then
    # shellcheck disable=SC2046
    apt-get install -y $(Data get-values provider-package)
fi

# Restore sudoers file
debian-setup/sudo

debian-setup/most

debian-setup/locales

# Before tzdata
debian-setup/rsyslog
debian-setup/tzdata

debian-setup/localepurge
debian-setup/unattended-upgrades

# Custom APT repository script
Dinstall package/apt-add-repo.sh

#debian-setup/ifupdown

debian-setup/_resolv_conf

# Block dangerous networks
# @FIXME Dependencies in ${D}
( cd /usr/local/src/debian-server-tools/security/myattackers-ipsets/; ./ipset-install.sh )

debian-setup/unscd

debian-setup/kmod

debian-setup/_swap

debian-setup/mount

debian-setup/initscripts

# Alert on boot and on halt
Dinstall monitoring/boot-alert
Dinstall monitoring/halt-alert
insserv -v boot-alert
insserv -v halt-alert

# IRQ balance
CPU_COUNT="$(grep -c "^processor" /proc/cpuinfo)"
if [ "$CPU_COUNT" -gt 1 ]; then
    apt-get install -y irqbalance
    cat /proc/interrupts
fi

# Time synchronization
# (util-linux)
sed -i -e 's|^#*HWCLOCKACCESS\b.*$|HWCLOCKACCESS=no|' /etc/default/hwclock
# @TODO
# if dmesg | grep -w "kvm-clock" \
#     || grep "kvm-clock" /sys/devices/system/clocksource/clocksource0/current_clocksource; then
#     # Display clock sources
#     cat /sys/devices/system/clocksource/clocksource0/available_clocksource
#     echo "https://s19n.net/articles/2011/kvm_clock.html"
# fi
if [ "$VIRT" == "kvm" ] && [ "$WITHOUT_SYSTEMD" == "yes" ]; then
    apt-get install -t jessie-backports -y libseccomp2
    apt-get install -y chrony
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
    apt-get install -y haveged
    cat /proc/sys/kernel/random/entropy_avail
fi

if [ "$VIRT" == "xen" ]; then
    debian-setup/_virt-xen
fi
if [ "$VIRT" == "vmware" ]; then
    debian-setup/_virt-vmware
fi

if [ -n "$(Data get-value software.serclient)" ]; then
    debian-setup/serclient
fi

debian-setup/cron

debian-setup/logrotate

debian-setup/debsums

debian-setup/openssh-client

# Nice welcome message
debian-setup/libpam-modules

debian-setup/mc

# myattackers
Dinstall security/myattackers.sh
# Initialize iptables chain
myattackers.sh -i

debian-setup/fail2ban

#debian-setup/_cert-szepenet

# Monitor certificates
Dinstall monitoring/cert-expiry.sh

# Courier MTA - deliver all messages to a smarthost
# See /mail/courier-mta-satellite-system.sh

if Is_installed "msmtp-mta"; then
    debian-setup/msmtp-mta
fi

# Monit - monitoring
# @FIXME Dependencies in ${D}
( cd /usr/local/src/debian-server-tools/monitoring/monit/; \
    install --mode=0640 -D -t /etc/monit monit.defaults; ./monit-debian-setup.sh )

# Munin - network-wide graphing
# @TODO See /monitoring/munin/munin-debian-setup.sh

#debian-setup/proftpd-basic

debian-setup/_package-python-pip
#debian-setup/_package-php-composer
debian-setup/php-wpcli
#debian-setup/php-drush
#debian-setup/nodejs

# Tools
for TOOL in catconf cnet hosthost hostinfo ip.sh lsrev msec reboot revip \
    sortip swap-usage.sh u udrush uwp whichdo whoistop; do
    Dinstall "$TOOL"
done



### WEBSERVER

# Apache 2.4
webserver/apache-httpd.sh
#debian-setup/mod-pagespeed-stable
# PHP-FPM
#webserver/php5-fpm.sh
webserver/php7-fpm.sh
# Redis server and PHP extension
webserver/redis-php.sh
# MariaDB
debian-setup/mariadb-server
# Add the development website
webserver/add-prg-site-auto.sh
# Add a production website
# See /webserver/add-site.sh

# @TODO Backup



### END

# Clean up
apt-get autoremove --purge

# Throttle package downloads (1000 kB/s)
echo 'Acquire::Queue-mode "access"; Acquire::http::Dl-Limit "1000";' > /etc/apt/apt.conf.d/76download

# At last
debian-setup/etckeeper

# Clear history
history -c
