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
apt-get install -y \
    ipset time netcat-openbsd lftp \
    ncurses-term bash-completion mc htop most less
    localepurge unattended-upgrades apt-listchanges cruft debsums etckeeper \
    gcc libc6-dev make strace \
    moreutils logtail whois unzip heirloom-mailx apg dos2unix ccze git colordiff mtr-tiny ntpdate
# Backports
apt-get install -t jessie-backports -y needrestart unscd
# From custom repos
apt-get install -y goaccess ipset-persistent

# Provider packages
if [ -n "$(Data get-value provider-package)" ]; then
    # shellcheck disable=SC2046
    apt-get install -y $(Data get-values provider-package)
fi

# Custom APT repository script
Dinstall package/apt-add-repo.sh

#debian-setup/ifupdown

debian-setup/_resolv_conf

# Block dangerous networks
# @FIXME Dependencies in ${D}
( cd /usr/local/src/debian-server-tools/security/myattackers-ipsets/; ./ipset-install.sh )
Dinstall security/myattackers.sh
# Initialize iptables chain
myattackers.sh -i

debian-setup/unscd

debian-setup/most

debian-setup/kmod

debian-setup/mount

# Entropy - check virtio_rng on KVM
if [ "$(dpkg-query --showformat="\${Status}" --show rng-tools 2> /dev/null)" == "install ok installed" ]; then
    [ -c /dev/hwrng ]
    cat /sys/devices/virtual/misc/hw_random/rng_{available,current}
else
    # Software based entropy source
    cat /proc/sys/kernel/random/entropy_avail
    apt-get install -y haveged
    cat /proc/sys/kernel/random/entropy_avail
fi

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

# Alert on boot and on halt
Dinstall monitoring/boot-alert
Dinstall monitoring/halt-alert
insserv -v boot-alert
insserv -v halt-alert

debian-setup/rsyslog

debian-setup/cron

debian-setup/libpam-modules

debian-setup/mc

# Monitor certificates
Dinstall monitoring/cert-expiry.sh

# Tools
for TOOL in catconf cnet hosthost hostinfo ip.sh lsrev msec reboot revip \
    sortip swap-usage.sh u udrush uwp whichdo whoistop; do
    Dinstall "$TOOL"
done

# Courier MTA - deliver all messages to a smarthost
# See /mail/courier-mta-satellite-system.sh

# Monit - monitoring
# @FIXME Dependencies in ${D}
( cd /usr/local/src/debian-server-tools/monitoring/monit/; \
    install --mode=0640 -D -t /etc/monit monit.defaults; ./monit-debian-setup.sh )

# Munin - network-wide graphing
# @TODO See /monitoring/munin/munin-debian-setup.sh



### WEBSERVER

# Apache 2.4
webserver/apache-httpd.sh
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



### END

# Clean up
apt-get autoremove --purge

# Throttle package downloads (1000 kB/s)
echo 'Acquire::Queue-mode "access"; Acquire::http::Dl-Limit "1000";' > /etc/apt/apt.conf.d/76download

# Save configuration
debconf-get-selections > "/root/debconf.selections"
dpkg --get-selections > "/root/packages.selection"

# Clear history
history -c
