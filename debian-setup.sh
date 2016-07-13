#!/bin/bash
#
# Debian jessie setup on a virtual server.
#
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# AUTORUN       :wget -O ds.sh http://git.io/vtcLq && . ds.sh

# How to choose VPS provider?
#
# 1.  Data center location
# 2.  Price
#     Has own AS? Number of peers
# 3.  Redundancy (power, network, storage, hypervisor)
#     Free scheduled backup
# 4.  Response time of nighttime technical support in case of network or hardware failure
# 5.  Disk access time (~1 ms)
# 6.  CPU speed (PassMark CPU Mark 2000+, sysbench < 20 ms, WordPress Speedtest 100-150 ms)
# 7.  Memory speed (bandwidth64)
# 8.  Network: worldwide and regional bandwidth, port speed, D/DoS mitigation
# 9.  Spammer neighbors http://www.projecthoneypot.org/ http://www.senderbase.org/lookup/
# 10. Daytime technical and billing support
#
# See: https://github.com/szepeviktor/wordpress-speedtest/blob/master/README.md#results

# Packages sources
DS_MIRROR="http://debian-archive.trafficmanager.net/debian"
#DS_MIRROR="http://cloudfront.debian.net/debian"
#DS_MIRROR="http://ftp.COUNTRY-CODE.debian.org/debian"

DS_REPOS="dotdeb szepeviktor nodejs percona goaccess"
#DS_REPOS="apache-backports deb-multimedia docker mod-pagespeed mt-aws-glacier \
#    mysql-server newrelic nginx obnam oracle postgre suhosin varnish"

# OVH configuration
#     /etc/ovhrc
#     cdns.ovh.net.
#     ntp.ovh.net. (id-co.in. ntp.cornuwel.net. ntp.syari.net. fry.helpfulhosting.net.)
#     http://help.ovh.com/InstallOvhKey
#     http://help.ovh.com/RealTimeMonitoring

# EZIT configuration
#     dnsc1.ezit.hu. dnsc2.ezit.hu.
#     ntp.ezit.hu.

set -e -x

Error() { echo "ERROR: $(tput bold;tput setaf 7;tput setab 1)$*$(tput sgr0)" 1>&2; }

[ "$(id -u)" == 0 ] || exit 1

# Identify distribution
lsb_release -a && sleep 5

# Download this repo
#apt-get install -y wget ca-certificates
mkdir /root/src
cd /root/src
wget -O- https://github.com/szepeviktor/debian-server-tools/archive/master.tar.gz|tar xz
cd debian-server-tools-master/
D="$(pwd)"

# Clean package cache
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get clean
apt-get autoremove --purge -y

# Packages sources
mv -f /etc/apt/sources.list "/etc/apt/sources.list~"
cp ${D}/package/apt-sources/sources.list /etc/apt/
sed -i -e "s;@@MIRROR@@;${DS_MIRROR};g" /etc/apt/sources.list
# Install HTTPS transport
apt-get update
apt-get install -y debian-archive-keyring apt-transport-https
for R in ${DS_REPOS};do cp ${D}/package/apt-sources/${R}.list /etc/apt/sources.list.d/;done
eval "$(grep -h -A5 "^deb " /etc/apt/sources.list.d/*.list|grep "^#K: "|cut -d' ' -f2-)"
#editor /etc/apt/sources.list

# APT settings
echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/00languages
echo 'APT::Periodic::Download-Upgradeable-Packages "1";' > /etc/apt/apt.conf.d/20download-upgrade
# 'APT::Install-Recommends "1";'

# Upgrade
apt-get update
apt-get dist-upgrade -y --force-yes
apt-get install -y lsb-release xz-utils ssh sudo ca-certificates most less lftp \
    time bash-completion htop host netcat-openbsd mc ncurses-term aptitude iproute2 ipset

# Input
sed -i 's/^# \(".*: history-search-.*ward\)$/\1/' /etc/inputrc
update-alternatives --set pager /usr/bin/most
update-alternatives --set editor /usr/bin/mcedit

# Bash
#sed -e 's/\(#.*enable bash completion\)/#\1/' -e '/#.*enable bash completion/,+8 { s/^#// }' -i /etc/bash.bashrc
echo "dash dash/sh boolean false" | debconf-set-selections -v
dpkg-reconfigure -f noninteractive dash
set +x
source /etc/profile.d/bash_completion.sh || Error "bash_completion.sh"

# --- Automated --------------- >8 ------------- >8 ------------
#grep -B1000 "# -\+ Automated -\+" debian-setup.sh
set +e +x
kill -SIGINT $$

# Virtualization environment
apt-get install -y virt-what && virt-what
apt-get purge -y virt-what

# Remove systemd
# http://without-systemd.org/wiki/index.php/How_to_remove_systemd_from_a_Debian_jessie/sid_installation
dpkg -s systemd &> /dev/null && apt-get install -y sysvinit-core sysvinit-utils \
    && cp -v /usr/share/sysvinit/inittab /etc/inittab
read -r -s -e -p 'Ctrl + D to reboot ' || reboot

apt-get purge -y --auto-remove systemd
echo -e 'Package: *systemd*\nPin: origin ""\nPin-Priority: -1' > /etc/apt/preferences.d/systemd

# Wget defaults TODO to user settings
echo -e "\ncontent_disposition = on" >> /etc/wgetrc

# User settings for non-login shells
editor /root/.bashrc

# ---------------------------------------------------------------------

#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

#export IP="$(ip addr show dev eth0|sed -ne 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p')"
export IP="$(ifconfig|sed -ne '0,/^\s*inet addr:\([0-9\.]\+\)\b.*$/s//\1/p')"
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

export GREP_OPTIONS="--color"
#alias grep='grep $GREP_OPTIONS'
alias iotop='iotop -d 0.1 -qqq -o'
alias iftop='NCURSES_NO_UTF8_ACS=1 iftop -nP'
alias transit='xz -9|base64 -w $((COLUMNS-1))'
alias transit-receive='base64 -d|xz -d'
alias changelog='xargs -I% -- zless /usr/share/doc/%/changelog.Debian.gz <<<'
#alias readmail='MAIL=/var/mail/MAILDIR/ mailx'
#     apt-get install -y tcpdump tcpflow
#alias httpdump='tcpdump -i eth0 -nn -s 1500 -l -w - "dst port 80 and dst host ${IP}" | tcpflow -c -r -'
# http://www.vim.org/scripts/script.php?script_id=658
#alias email='vim -c "startinsert" /tmp/e.eml'

# ---------------------------------------------------------------------

# User settings for login shells
editor /root/.profile

# ---------------------------------------------------------------------

PS1exitstatus() { local RET="$?";if [ "$RET" -ne 0 ];then echo -n "$(tput setaf 7;tput setab 1)"'!'"$RET";fi; }
# Yellow + Cyan: $(tput setaf 3) \u $(tput bold;tput setaf 6)
export PS1="\[$(tput sgr0)\][\[$(tput setaf 3)\]\u\[$(tput bold;tput setaf 1)\]@\h\[$(tput sgr0)\]:\
\[$(tput setaf 8;tput setab 4)\]\w\[$(tput sgr0)\]:\t:\
\[$(tput bold)\]\!\[\$(PS1exitstatus;tput sgr0)\]]\n"

# putty Connection / Data / Terminal-type string: putty-256color
# ls -1 /usr/share/mc/skins/|sed "s/\.ini$//g"
if [ "${TERM/256/}" == "$TERM" ]; then
    if [ "$(id -u)" == 0 ]; then
        export MC_SKIN="modarcon16root-defbg-thin"
    else
        export MC_SKIN="modarcon16"
    fi
else
    if [ "$(id -u)" == 0 ]; then
        export MC_SKIN="modarin256root-defbg-thin"
    else
        export MC_SKIN="xoria256"
    fi
fi

# Colorized man pages with less
#     update-alternatives --set pager /usr/bin/less
#     man termcap # String Capabilities
man() {
    #
    #     so   Start standout mode (search)
    #     se   End standout mode
    #     us   Start underlining (italic)
    #     ue   End underlining
    #     md   Start bold mode (highlight)
    #     me   End all mode like so, us, mb, md and mr
    env \
        LESS_TERMCAP_so=$(tput setab 230) \
        LESS_TERMCAP_se=$(tput sgr0) \
        LESS_TERMCAP_us=$(tput setaf 2) \
        LESS_TERMCAP_ue=$(tput sgr0) \
        LESS_TERMCAP_md=$(tput bold) \
        LESS_TERMCAP_me=$(tput sgr0) \
        man "$@"
}

# ---------------------------------------------------------------------

# Set the title on putty terminals
sed -i 's;^xterm\*|rxvt\*);xterm*|rxvt*|putty*);' /etc/skel/.bashrc

# Markdown for mc
#cp -v /etc/mc/mc.ext ~/.config/mc/mc.ext && apt-get install -y pandoc
#editor ~/.config/mc/mc.ext
#    regex/\.md(own)?$
#    	View=pandoc -s -f markdown -t man %p | man -l -

# Add INI extensions for mc syntax highlighting
cp -v /usr/share/mc/syntax/Syntax ~/.config/mc/mcedit/Syntax
sed -i 's;^\(file .*\[nN\]\[iI\]\)\(.*\)$;\1|cf|conf|cnf|local|htaccess\2;' ~/.config/mc/mcedit/Syntax
sed -i 's;^\(file .*(\)py|PY\().*\)$;\1py|PY|yml|yaml\2;' ~/.config/mc/mcedit/Syntax
sed -i 's;^file sources.list\$ sources\\slist$;file (sources)?\\.list$ sources\\slist;' ~/.config/mc/mcedit/Syntax
#editor ~/.config/mc/mcedit/Syntax

# Username
U="viktor"
# GECOS: Full name,Room number,Work phone,Home phone
adduser --gecos "" "$U"
# <<< Enter password twice
K="PUBLIC_KEY"
S="$(getent passwd "$U"|cut -d: -f6)/.ssh";mkdir --mode 700 "$S";echo "$K">>"${S}/authorized_keys2";chown -R ${U}:${U} "$S"
adduser ${U} sudo
# Expire password
#     passwd -e ${U}

# Change root and other passwords to "*"
editor /etc/shadow

# Hostname
# Set A record and PTR record
# Consider: http://www.iata.org/publications/Pages/code-search.aspx
#           http://www.world-airport-codes.com/
read -r -e -p "Host name? " H
# Search for the old hostname
grep -ir "$(hostname)" /etc/
hostname "$H"
echo "$H" > /etc/hostname
echo "$H" > /etc/mailname
# See: man hosts
editor /etc/hosts
#     127.0.0.1 localhost
#     127.0.1.1 localhost
#     ::1     ip6-localhost ip6-loopback
#     fe00::0 ip6-localnet
#     ff00::0 ip6-mcastprefix
#     ff02::1 ip6-allnodes
#     ff02::2 ip6-allrouters
#
#     # ORIGINAL-PTR $(host "$IP")
#     IP.IP.IP.IP HOST.DOMAIN HOST
host "$H"
# Reverse DNS record (PTR)
host "$IP"

# SSH
read -r -s -e -p "SSH port? " SSH_PORT
# Change port (no "22"-s)
sed "s/^Port 22$/#Port 22\nPort ${SSH_PORT}/" -i /etc/ssh/sshd_config
# Disable root login
sed 's/^PermitRootLogin \(yes\|without-password\)$/PermitRootLogin no/' -i /etc/ssh/sshd_config
# Disable DSA host key
sed "s|^HostKey\s\+/etc/ssh/ssh_host_dsa_key|#HostKey /etc/ssh/ssh_host_dsa_key|" -i /etc/ssh/sshd_config
# Change host keys
rm -vf /etc/ssh/ssh_host_*
# Disable password login for sudoers
echo -e "\nMatch Group sudo\n    PasswordAuthentication no" >> /etc/ssh/sshd_config
# Add blocked networks
# See: /security/README.md
editor /etc/hosts.deny
dpkg-reconfigure -f noninteractive openssh-server && service ssh restart
# Check sshd
service ssh status
netstat -antup | grep sshd

# Log out as root
logout

# Log in
sudo su - || exit
D="/root/src/debian-server-tools-master"

# Download architecture-independent packages
Getpkg() { local P="$1"; local R="${2-sid}"; local WEB="https://packages.debian.org/${R}/all/${P}/download";
    local URL="$(wget -qO- "$WEB"|grep -o '[^"]\+ftp.fr.debian.org/debian[^"]\+\.deb')";
    [ -z "$URL" ] && return 1; wget -qO "${P}.deb" "$URL" && dpkg -i "${P}.deb"; echo "Ret=$?"; }

# Hardware
lspci
[ -f /proc/modules ] && lsmod || echo "WARNING: monolithic kernel"
# TODO intel_rapl

# Disk configuration
clear; cat /proc/mdstat; cat /proc/partitions
pvdisplay && vgdisplay && lvdisplay
clear; ls -1 /etc/default/*
head -n 1000 /etc/default/* | grep -vE '^\s*#|^\s*$' | grep --color -A1000 "^==> "

# Mount /tmp in RAM
TOTAL_MEM="$(grep MemTotal /proc/meminfo|sed 's;.*[[:space:]]\([0-9]\+\)[[:space:]]kB.*;\1;')"
[ "$TOTAL_MEM" -gt $((4097 * 1024)) ] && sed -i 's/^#RAMTMP=no$/RAMTMP=yes/' /etc/default/tmpfs

# Mount points
# <file system> <mount point>             <type>          <options>                               <dump> <pass>
clear; editor /etc/fstab
clear; cat /proc/mounts
swapoff -a; swapon -a; cat /proc/swaps

# Create swap file
dd if=/dev/zero of=/swap0 bs=1M count=768
chmod 0600 /swap0
mkswap /swap0
echo "/swap0    none    swap    sw    0   0" >> /etc/fstab

# relAtime option for filesystems
grep --color "\S\+\s\+/\s.*relatime" /proc/mounts || echo "ERROR: no relAtime for rootfs"

# Kernel
uname -a
# List available kernel versions
apt-cache policy "linux-image-[3456789].*"
#apt-get install linux-image-amd64=KERNEL-VERSION
# More than 1 kernel?
#aptitude --disable-columns -F"%p" search '?and(?installed, ?name(^linux-image-))'|grep -vFx "linux-image-$(dpkg --print-architecture)"
clear; ls -l /lib/modules/
ls -latr /boot/

# Verbose boot
sed -i 's/^#*VERBOSE=no$/VERBOSE=yes/' /etc/default/rcS
dpkg -l | grep "grub"
# OVH Kernel "made-in-ovh"
#     ${D}/security/ovh-kernel-update.sh
# Linode Kernels: auto renew on reboot
#     https://www.linode.com/kernels/
editor /etc/modules
clear; ls -1 /etc/sysctl.d/ | grep -v README.sysctl
editor /etc/sysctl.conf

# Inittab on SysVinit
# Comment out getty[2-6], NOT /etc/init.d/rc
# Consider /sbin/agetty
#     1:2345:respawn:/sbin/agetty 38400 tty1
editor /etc/inittab

# Xen Serial Console
# SysVinit
editor /etc/inittab
#     s1:2345:respawn:/sbin/agetty -L ttyS0 115200 vt102
# Systemd
systemctl enable serial-getty@ttyS0.service
systemctl start serial-getty@ttyS0.service


# Miscellaneous configuration
editor /etc/rc.local
editor /etc/profile
ls -l /etc/profile.d/
# Aruba needs arping package for /etc/rc.local
apt-get install -y arping
# See: /input/motd-install.sh

# Networking
editor /etc/network/interfaces
#     source /etc/network/interfaces.d/*
#
#     allow-hotplug eth0
#     auto eth0
#     iface eth0 inet static
#         address INET-IP/INET-NETMASK
#         gateway GATEWAY
#         #netmask INET-NETMASK
#         #dns-nameservers INET-NS1
#     iface eth0 inet6 auto
#         dns-nameservers INET6-NS1
#     #iface eth0 inet6 static
#     #    address INET6-IP/INET6-NETMASK
#     #    gateway INET6-GW
clear; ifconfig -a
route -n -4
route -n -6
netstat -antup

editor /etc/resolv.conf
#     # Google Public DNS
#     nameserver 8.8.8.8
#     nameserver LOCAL-NS
#     nameserver LOCAL-NS2
#     nameserver 8.8.4.4
#     #nameserver 2001:4860:4860:0:0:0:0:8888
#     #nameserver 2001:4860:4860:0:0:0:0:8844
#     options timeout:2
#     #options rotate

#     # DNS Advantage by Neustar
#     nameserver 156.154.71.1
#     nameserver LOCAL-NS
#     nameserver LOCAL-NS2
#     nameserver 156.154.70.1
#     options timeout:2
#     #options rotate

# Aruba resolvers
#     DC1-IT 62.149.128.4 62.149.132.4
#     DC3-CZ 81.2.192.131 81.2.193.227
#
# Vultr resolvers
#     Frankfurt 108.61.10.10
#
# EZIT resolvers
#     BIX 87.229.108.201 80.249.168.18
#
# OVH resolvers
#     France 213.186.33.99
#
# ATW resolvers
#     BIX 88.151.96.15 88.151.96.16 2a01:270::15 2a01:270::16

clear; ping6 -c 4 ipv6.google.com
host -v -tA example.com|grep "^example\.com\.\s*[0-9]\+\s*IN\s*A\s*93\.184\.216\.34$"||echo "DNS error"
# View network Graph v4/v6
#     http://bgp.he.net/ip/${IP}

# SSL support
rm -f /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key
# Update ca-certificates
wget -qO- http://metadata.ftp-master.debian.org/changelogs/main/c/ca-certificates/unstable_changelog|less
Getpkg ca-certificates
# Monitor certificates
( cd ${D}; ./install.sh monitoring/cert-expiry.sh )

# Install szepenet CA
CA_NAME="szepenet"
CA_FILE="szepenet_ca.crt"
mkdir -v /usr/local/share/ca-certificates/${CA_NAME}
cp -v ${D}/security/ca/ca-web/szepenet-ca.pem /usr/local/share/ca-certificates/${CA_NAME}/${CA_FILE}
# Update certificates
update-ca-certificates -v -f

# Locale and timezone
clear; locale; locale -a
echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections -v
echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections -v
dpkg-reconfigure -f noninteractive locales
# UTC timezone
# http://yellerapp.com/posts/2015-01-12-the-worst-server-setup-you-can-make.html
cat /etc/timezone
echo "tzdata tzdata/Areas select Etc" | debconf-set-selections -v
echo "tzdata tzdata/Zones/Etc select UTC" | debconf-set-selections -v
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=704089
rm -f /etc/timezone
dpkg-reconfigure -f noninteractive tzdata && service rsyslog restart

# Review packages
dpkg -l | pager
# Show debconf changes
debconf-show --listowners | xargs -n 1 debconf-show | grep "^\*"
# Find broken symlinks
find / -type l -xtype l -not -path "/proc/*"
debsums --all --changed | tee debsums-changed.log
# Check MD5 hashes of installed packages
for L in /var/lib/dpkg/info/*.list;do P=$(basename "$L" .list);[ -r "/var/lib/dpkg/info/${P}.md5sums" ]||echo "$P";done
# Sanitize files
rm -vrf /var/lib/clamav /var/log/clamav
read -r -e -p "Hosting company? " HOSTING_COMPANY
find / -iname "*${HOSTING_COMPANY}*"
grep -ir "${HOSTING_COMPANY}" /etc/
dpkg -l | grep -i "${HOSTING_COMPANY}"

# Sanitize users
#     https://www.debian.org/doc/debian-policy/ch-opersys.html#s9.2
#     https://www.debian.org/doc/manuals/securing-debian-howto/ch12.en.html#s-faq-os-users
# mcview /usr/share/doc/base-passwd/users-and-groups.html
tabs 20,+3,+8,+8,+20,+20,+8,+8,+8;sort -t':' -k3 -g /etc/passwd|tr ':' '\t';tabs -8
editor /etc/passwd
editor /etc/shadow
update-passwd -v --dry-run
#update-passwd -v

# Essential packages
apt-get install -y localepurge unattended-upgrades apt-listchanges cruft debsums \
    ipset-persistent moreutils logtail whois unzip heirloom-mailx \
    apg dos2unix git colordiff mtr-tiny ntpdate \
    gcc libc6-dev make strace ccze goaccess
# Backports
apt-get install -t jessie-backports -y needrestart

# SysVinit
apt-get install -y bootlogd

# Alert on boot and on halt
cp -v ${D}/monitoring/boot-alert /etc/init.d/
update-rc.d boot-alert defaults
cp -v ${D}/monitoring/halt-alert /etc/init.d/
update-rc.d halt-alert defaults

# debsums weekly cron job
sed -i 's/^CRON_CHECK=never.*$/CRON_CHECK=weekly/' /etc/default/debsums

# Check user cron jobs
clear; ${D}/tools/catconf /etc/crontab /var/spool/cron/crontabs/*

# Automatic security updates
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true"|debconf-set-selections -v
dpkg-reconfigure -f noninteractive unattended-upgrades

# Custom APT repositories
( cd ${D}; ./install.sh package/apt-add-repo.sh )
#editor /etc/apt/sources.list.d/others.list && apt-get update

# Block dangerous networks
( cd ${D}/security/myattackers-ipsets/; ./ipset-install.sh )
( cd ${D}; ./install.sh security/myattackers.sh )
# Initialize iptables chain
myattackers.sh -i


# Create directory for non-distribution files
cd /root/; mkdir dist-mod && cd dist-mod/

# Get pip
apt-get install -y python3-dev
wget -nv https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
python2 get-pip.py

# rsyslogd immark plugin
#     http://www.rsyslog.com/doc/rsconf1_markmessageperiod.html
editor /etc/rsyslog.conf
#     $ModLoad immark
#     $MarkMessagePeriod 1800
#
#     # Alert root
#     *.warn  :omusrmsg:root,viktor
service rsyslog restart

# Debian tools
cd /usr/local/src/ && git clone --recursive https://github.com/szepeviktor/debian-server-tools.git
D="$(pwd)/debian-server-tools"
rm -rf /root/src/debian-server-tools-master/
( cd ${D}; ls tools/ | xargs -I "%%" ./install.sh tools/%% )

# CPU
grep -E "model name|cpu MHz|bogomips" /proc/cpuinfo
# Explain Intel CPU flags
( cd /root/dist-mod/
wget https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/plain/arch/x86/include/asm/cpufeatures.h
for FLAG in $(grep -m1 "^flags" /proc/cpuinfo|cut -d":" -f2-); do echo -n "$FLAG"
 grep -C1 "^#define X86_\(FEATURE\|BUG\)_" cpufeatures.h \
 | grep -E -i -m1 "/\* \"${FLAG}\"|^#define X86_(FEATURE|BUG)_${FLAG}" \
 | grep -o './\*.*\*/' || echo "N/A"; done )

# CPU frequency scaling governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# Set performance mode
#for SG in /sys/devices/system/cpu/*/cpufreq/scaling_governor;do echo "performance" > $SG;done

# Entropy - check virtio_rng on KVM
cat /sys/devices/virtual/misc/hw_random/rng_{available,current}
[ -c /dev/hwrng ] && apt-get install -y rng-tools
# Software based entropy source
cat /proc/sys/kernel/random/entropy_avail
apt-get install -y haveged
cat /proc/sys/kernel/random/entropy_avail

# IRQ balance
declare -i CPU_COUNT="$(grep -c "^processor" /proc/cpuinfo)"
[ "$CPU_COUNT" -gt 1 ] && apt-get install -y irqbalance && cat /proc/interrupts

# Make cron log all failed jobs (exit status != 0)
sed -i "s/^#\s*\(EXTRA_OPTS='-L 5'\)/\1/" /etc/default/cron || echo "ERROR: cron-default"
# Add healthchecks.io check
read -r -e -p "hchk.io URL=" HCHK_URL
echo -e "03 *\t* * *\tnobody\twget -q -t 3 -O- ${HCHK_URL} | grep -qFx 'OK'" > /etc/cron.d/healthchecks
service cron restart

# Time synchronization
( cd ${D}; ./install.sh monitoring/monit/services/ntpdate_script )
echo -e '#!/bin/bash\n/usr/local/bin/ntp-alert.sh' > /etc/cron.daily/ntp-alert
chmod +x /etc/cron.daily/ntp-alert
# Virtual servers only
editor /etc/default/hwclock
#    HWCLOCKACCESS=no
# Check clock source
cat /sys/devices/system/clocksource/clocksource0/available_clocksource
# KVM (???no ntp)
# https://s19n.net/articles/2011/kvm_clock.html
dmesg | grep "kvm-clock"
grep "kvm-clock" /sys/devices/system/clocksource/clocksource0/current_clocksource
# VMware (no ntp)
# @FIXME It is necessary on every boot?
vmware-toolbox-cmd timesync enable
vmware-toolbox-cmd timesync status
# Chrony
apt-get install -y libseccomp2/jessie-backports chrony
editor /etc/chrony/chrony.conf
#     pool 0.de.pool.ntp.org offline iburst
#     pool 0.cz.pool.ntp.org offline iburst
#     pool 0.hu.pool.ntp.org offline iburst
#     pool 0.fr.pool.ntp.org offline iburst
#     pool 0.uk.pool.ntp.org offline iburst
#     # OVH
#     server ntp.ovh.net offline iburst
#     # EZIT
#     server ntp.ezit.hu offline iburst
#
#     logchange 0.010
#     cmdport 0
#     # Don't set hardware clock (RTC)
#     ##rtcsync
service chrony restart
# Systemd
timedatectl set-ntp 1

# µnscd
apt-get install -t jessie-backports -y unscd
editor /etc/nscd.conf
#     enable-cache            hosts   yes
#     positive-time-to-live   hosts   60
#     negative-time-to-live   hosts   20
service unscd stop && service unscd start

# msmtp (has no queue!)
apt-get install -y msmtp-mta
# /usr/share/doc/msmtp/examples/msmtprc-system.example
cp -vf ${D}/mail/msmtprc /etc/
# Configure Mandrill
#     https://www.mandrill.com/signup/
#     http://msmtp.sourceforge.net/doc/msmtp.html
echo "This is a test mail."|mailx -s "[first] Subject of the first email" ADDRESS

# Courier MTA - deliver all messages to a smarthost
# See: /mail/courier-mta-satellite-system.sh

# Apache 2.4 with mpm-events
apt-get install -y apache2 apache2-utils
adduser --disabled-password --gecos "" web
editor /etc/apache2/envvars
#     export APACHE_RUN_USER=web
#     export APACHE_RUN_GROUP=web

a2enmod actions rewrite headers deflate expires proxy_fcgi
# Comment out '<Location /server-status>' block
editor /etc/apache2/mods-available/status.conf
a2enmod ssl
cp -v ${D}/webserver/apache-conf-available/*.conf /etc/apache2/conf-available/
yes|cp -vf ${D}/webserver/apache-sites-available/*.conf /etc/apache2/sites-available/
echo -e "User-agent: *\nDisallow: /\n# Please stop sending further requests." > /var/www/html/robots.txt
( cd ${D}; ./install.sh webserver/apache-resolve-hostnames.sh )
( cd ${D}; ./install.sh webserver/wp-cron-cli.sh )

# Use php-fpm.conf settings per site
a2enconf h5bp
editor /etc/apache2/conf-enabled/security.conf
#     ServerTokens Prod
editor /etc/apache2/apache2.conf
#     LogLevel info

# mod_pagespeed for poorly written websites
apt-get install -y mod-pagespeed-stable
# Remove duplicate
ls -l /etc/apt/sources.list.d/*pagespeed*
#rm -v /etc/apt/sources.list.d/mod-pagespeed.list

# Apache security
https://github.com/rfxn/linux-malware-detect
https://github.com/Neohapsis/NeoPI

# Nginx 1.8
apt-get install -y nginx-lite
# Nginx packages: lite, full, extra
#    https://docs.google.com/a/moolfreet.com/spreadsheet/ccc?key=0AjuNPnOoex7SdG5fUkhfc3BCSjJQbVVrQTg4UGU2YVE#gid=0
#    apt-get install -y nginx-full
# Put ngx-conf in PATH
ln -sv /usr/sbin/ngx-conf/ngx-conf /usr/local/sbin/ngx-conf
# HTTP/AUTH
mkdir /etc/nginx/http-auth
# Configuration
#    https://codex.wordpress.org/Nginx
#    http://wiki.nginx.org/WordPress
git clone https://github.com/szepeviktor/server-configs-nginx.git
NGXC="/etc/nginx"
cp -va h5bp/ ${NGXC}
cp -vf mime.types ${NGXC}
cp -vf nginx.conf ${NGXC}
ngx-conf --disable default
cp -vf sites-available/no-default ${NGXC}/sites-available
ngx-conf --enable no-default

# Fail2ban
#     https://packages.qa.debian.org/f/fail2ban.html
( cd /root/dist-mod/; Getpkg geoip-database-contrib )
apt-get install -y geoip-bin python3-pyinotify
#( cd /root/dist-mod/; Getpkg fail2ban )
# From szepeviktor repo
apt-get install -y fail2ban
mc ${D}/security/fail2ban-conf/ /etc/fail2ban/
# Config:     fail2ban.local
# Jails:      jail.local
# /filter.d:  apache-combined.local, apache-instant.local, courier-smtp.local, recidive.local
# /action.d:  cloudflare.local
# Search for "@@"
service fail2ban restart

# PHP 5.6
apt-get install -y php5-cli php5-curl php5-fpm php5-gd \
    php5-mcrypt php5-mysqlnd php5-readline php5-dev \
    php5-sqlite php5-apcu php-pear

# System-wide strict values
PHP_TZ="Europe/Budapest"
sed -i 's/^expose_php\s*=.*$/expose_php = Off/' /etc/php5/fpm/php.ini
sed -i 's/^max_execution_time\s*=.*$/max_execution_time = 65/' /etc/php5/fpm/php.ini
sed -i 's/^memory_limit\s*=.*$/memory_limit = 384M/' /etc/php5/fpm/php.ini
sed -i 's/^post_max_size\s*=.*$/post_max_size = 20M/' /etc/php5/fpm/php.ini
sed -i 's/^upload_max_filesize\s*=.*$/upload_max_filesize = 20M/' /etc/php5/fpm/php.ini
sed -i 's/^allow_url_fopen\s*=.*$/allow_url_fopen = Off/' /etc/php5/fpm/php.ini
sed -i "s|^;date.timezone\s*=.*\$|date.timezone = ${PHP_TZ}|" /etc/php5/fpm/php.ini
sed -i "s|^;mail.add_x_header\s*=.*\$|mail.add_x_header = Off|" /etc/php5/fpm/php.ini
# OPcache - only "prg" site is allowed
sed -i 's|^;opcache.restrict_api\s*=.*$|opcache.restrict_api = /home/web/website/|' /etc/php5/fpm/php.ini
sed -i 's/^;opcache.memory_consumption\s*=.*$/opcache.memory_consumption = 256/' /etc/php5/fpm/php.ini
sed -i 's/^;opcache.interned_strings_buffer\s*=.*$/opcache.interned_strings_buffer = 16/' /etc/php5/fpm/php.ini
# There may be more than 10k files
#     find /home/ -type f -name "*.php" | wc -l
sed -i 's/^;opcache.max_accelerated_files\s*=.*$/opcache.max_accelerated_files = 10000/' /etc/php5/fpm/php.ini
# APCu
echo -e "\n[apc]\napc.enabled = 1\napc.shm_size = 64M" >> /etc/php5/fpm/php.ini

# Pool-specific values go to pool configs

# @TODO Measure: realpath_cache_size = 16k  realpath_cache_ttl = 120
#       https://www.scalingphpbook.com/best-zend-opcache-settings-tuning-config/

grep -Ev "^\s*#|^\s*;|^\s*$" /etc/php5/fpm/php.ini | most
# Disable "www" pool
#sed -i 's/^/;/' /etc/php5/fpm/pool.d/www.conf
mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.default
cp -v ${D}/webserver/phpfpm-pools/* /etc/php5/fpm/
# PHP 5.6+ session cleaning
mkdir -p /usr/local/lib/php5
cp -v ${D}/webserver/sessionclean5.5 /usr/local/lib/php5/
# PHP 5.6+
echo -e "15 *\t* * *\troot\t[ -x /usr/local/lib/php5/sessionclean5.5 ] && /usr/local/lib/php5/sessionclean5.5" \
    > /etc/cron.d/php5-user

# @FIXME PHP timeouts
# - PHP max_execution_time
# - PHP max_input_time
# - Apache ProxyTimeout
# - FastCGI -idle-timeout
# - PHP-FPM pool request_terminate_timeout

# Suhosin extension
#     https://github.com/stefanesser/suhosin/releases
apt-get install -y php5-suhosin-extension
php5enmod -s fpm suhosin
# Disable for PHP-CLI
#     php5dismod -s cli suhosin
#     phpdismod -v ALL -s cli suhosin
# Disable suhosin
#     [suhosin]
#     suhosin.simulation = On
# Check priority
ls -l /etc/php5/fpm/conf.d/20-suhosin.ini

# @TODO Package realpath_turbo
# https://github.com/Whissi/realpath_turbo
# https://github.com/Mikk3lRo/realpath_turbo PHP7.0

# PHP file modification time protection
# https://ioncube24.com/signup

# @TODO .ini-handler, Search for it! ?ucf

# PHP security directives
#     mail.add_x_header
#     assert.active
#     suhosin.executor.disable_emodifier = On
#     suhosin.disable.display_errors = 1
#     suhosin.session.cryptkey = $(apg -m 32)

# PHP directives for Drupal
#     suhosin.get.max_array_index_length = 128
#     suhosin.post.max_array_index_length = 128
#     suhosin.request.max_array_index_length = 128

# No FPM pools -> no restart

# ionCube Loader
# https://www.ioncube.com/loaders.php
#     zend_extension = ioncube_loader_lin_5.6.so
#     ic24.enable = Off


# PHP 7.0
apt-get install -y php7.0-cli php7.0-fpm \
    php7.0-mbstring php7.0-mcrypt php7.0-json php7.0-intl \
    php7.0-readline php7.0-curl php7.0-gd php7.0-mysql php7.0-sqlite3
PHP_TZ="Europe/Budapest"
sed -i 's/^expose_php\s*=.*$/expose_php = Off/' /etc/php/7.0/fpm/php.ini
sed -i 's/^max_execution_time=.*$/max_execution_time = 65/' /etc/php/7.0/fpm/php.ini
sed -i 's/^memory_limit\s*=.*$/memory_limit = 128M/' /etc/php/7.0/fpm/php.ini
sed -i 's/^post_max_size\s*=.*$/post_max_size = 20M/' /etc/php/7.0/fpm/php.ini
sed -i 's/^upload_max_filesize\s*=.*$/upload_max_filesize = 20M/' /etc/php/7.0/fpm/php.ini
sed -i 's/^allow_url_fopen\s*=.*$/allow_url_fopen = Off/' /etc/php/7.0/fpm/php.ini
sed -i "s|^;date.timezone\s*=.*\$|date.timezone = ${PHP_TZ}|" /etc/php/7.0/fpm/php.ini
sed -i "s|^;mail.add_x_header\s*=.*\$|mail.add_x_header = Off|" /etc/php/7.0/fpm/php.ini
# Only Prg site is allowed
sed -i 's/^;opcache.memory_consumption\s*=.*$/opcache.memory_consumption = 256/' /etc/php/7.0/fpm/php.ini
sed -i 's/^;opcache.interned_strings_buffer\s*=.*$/opcache.interned_strings_buffer = 16/' /etc/php/7.0/fpm/php.ini
# Set username in $U
sed -i "s|^;opcache.restrict_api\s*=.*\$|opcache.restrict_api = /home/${U}/website/|" /etc/php/7.0/fpm/php.ini

# OPcache - There may be more than 2k files
#     find /home/ -type f -name "*.php"|wc -l
sed -i 's/^;opcache.max_accelerated_files\s*=.*$/opcache.max_accelerated_files = 10000/' /etc/php5/fpm/php.ini
# APCu
echo -e "\n[apc]\napc.enabled = 1\napc.shm_size = 64M" >> /etc/php5/fpm/php.ini

# @TODO Measure: realpath_cache_size = 16k  realpath_cache_ttl = 120
#       https://www.scalingphpbook.com/best-zend-opcache-settings-tuning-config/

grep -Ev "^\s*#|^\s*;|^\s*\$" /etc/php/7.0/fpm/php.ini | pager
# Disable "www" pool
mv -v /etc/php/7.0/fpm/pool.d/www.conf /etc/php/7.0/fpm/pool.d/www.conf.default
# Add skeletons
cp -v ${D}/webserver/phpfpm-pools/* /etc/php/7.0/fpm/
# PHP session cleaning
#/usr/lib/php/sessionclean

# @FIXME PHP timeouts
# - PHP max_execution_time
# - PHP max_input_time
# - FastCGI -idle-timeout
# - PHP-FPM pool request_terminate_timeout

# Suhosin extension for PHP 7.0
#     https://github.com/stefanesser/suhosin/releases
#apt-get install -y php5-suhosin-extension
#php5enmod -s fpm suhosin
# Check priority
ls -l /etc/php5/fpm/conf.d/70-suhosin.ini

# PHP file modification time protection
# https://ioncube24.com/signup

# @TODO .ini-handler, Search for it! ?ucf

# PHP security directives
#     mail.add_x_header
#     assert.active
#     suhosin.executor.disable_emodifier = On
#     suhosin.disable.display_errors = 1
#     suhosin.session.cryptkey = $(apg -m 32)

# PHP directives for Drupal
#     suhosin.get.max_array_index_length = 128
#     suhosin.post.max_array_index_length = 128
#     suhosin.request.max_array_index_length = 128

# No FPM pools -> no restart

# ionCube Loader
# https://www.ioncube.com/loaders.php
#     zend_extension = ioncube_loader_lin_5.6.so
#     ic24.enable = Off

# Webserver restart
( cd ${D}; ./install.sh webserver/webrestart.sh )

# Add the development website
# See: /webserver/add-prg-site.sh

# Add a production website
# See: /webserver/add-site.sh


# @TODO NoSQL object cache
# Redis


# MariaDB
apt-get install -y mariadb-server-10.0 mariadb-client-10.0 percona-xtrabackup
# OR Percona server
apt-get install -y percona-server-server-5.7 percona-server-client-5.7 percona-xtrabackup

# Disable the binary log
sed -i -e 's/^log_bin/#&/' /etc/mysql/my.cnf
read -r -s -e -p "MYSQL_PASSWORD? " MYSQL_PASSWORD
echo -e "[mysql]\nuser=root\npassword=${MYSQL_PASSWORD}\ndefault-character-set=utf8" >> /root/.my.cnf
echo -e "[mysqldump]\nuser=root\npassword=${MYSQL_PASSWORD}\ndefault-character-set=utf8" >> /root/.my.cnf
chmod 600 /root/.my.cnf
#editor /root/.my.cnf
# @TODO repl? bin_log? xtrabackup?


# WP-CLI
WPCLI_URL="https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
wget -O /usr/local/bin/wp "$WPCLI_URL" && chmod -c +x /usr/local/bin/wp
WPCLI_COMPLETION_URL="https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash"
wget -O- "$WPCLI_COMPLETION_URL"|sed 's/wp cli completions/wp --allow-root cli completions/' > /etc/bash_completion.d/wp-cli
# If you have suhosin in PHP-CLI configuration
#     grep "[^;#]*suhosin\.executor\.include\.whitelist.*phar" /etc/php5/cli/conf.d/*suhosin*.ini || Error "Whitelist phar"

# Composer
# Current hash: https://composer.github.io/pubkeys.html
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');
if (hash_file('SHA384', 'composer-setup.php') ===
'e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae')
{ echo 'Installer verified'; }
else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

# Drush
#     https://github.com/drush-ops/drush/releases
mkdir -p /opt/drush && cd /opt/drush
composer require drush/drush:7.*
ln -sv /opt/drush/vendor/bin/drush /usr/local/bin/drush
# Set up Drupal site
#     sudo -u SITE-USER -i
#     cd website/
#     drush dl drupal --drupal-project-rename=html
#     cd html/
#     drush site-install standard \
#         --db-url='mysql://DB-USER:DB-PASS@localhost/DB-NAME' \
#         --site-name=SITE-NAME --account-name=USER-NAME --account-pass=USER-PASS
#     drush --root=DOCUMENT-ROOT vset --yes file_private_path "PRIVATE-PATH"
#     drush --root=DOCUMENT-ROOT vset --yes file_temporary_path "UPLOAD-DIRECTORY"
#     drush --root=DOCUMENT-ROOT vset --yes cron_safe_threshold 0
#
# See: /webserver/preload-cache.sh

# Spamassassin
apt-get install -y libmail-dkim-perl \
    libsocket6-perl libsys-hostname-long-perl libnet-dns-perl libnetaddr-ip-perl \
    libcrypt-openssl-rsa-perl libdigest-hmac-perl libio-socket-inet6-perl libnet-ip-perl \
    libcrypt-openssl-bignum-perl
( cd /root/dist-mod/; Getpkg spamassassin )

# SSL certificate for web, mail etc.
# See: /security/new-ssl-cert.sh

# Test TLS connections
# See: /security/README.md

# ProFTPD
# When the default locale for your system is not en_US.UTF-8
# be sure to add this to /etc/default/proftpd for fail2ban to understand dates.
#     export LC_TIME="en_US.UTF-8"

# Simple syslog monitoring
( cd ${D}; ./install.sh monitoring/syslog-errors.sh )

# Monit - monitoring
( cd ${D}/monitoring/monit/; ./monit-debian-setup.sh )

# Munin - network-wide graphing
# See: /monitoring/munin/munin-debian-setup.sh

# Aruba ExtraControl (serclient)
#     http://admin.dc3.arubacloud.hu/Manage/Serial/SerialManagement.aspx
wget -nv https://admin.dc3.arubacloud.hu/Installers/debian/aruba-serclient_0.01-1_all.deb
dpkg -i aruba-serclient_*_all.deb
# Set log level
echo -e "[LOG]\nlevel = 20" >> /opt/serclient/serclient.ini
# Comment out "if getRestartGUID(remove=False) == None: rf.doRollover()"
editor /opt/serclient/tools.py:159
md5sum /opt/serclient/tools.py
editor /var/lib/dpkg/info/aruba-serclient.md5sums
# Add logrotate
editor /etc/logrotate.d/serclient
#     /var/log/serclient.log {
#         weekly
#         rotate 15
#         compress
#         delaycompress
#         notifempty
#         create 640 root root
#         postrotate
#                     if /etc/init.d/serclient status > /dev/null ; then \
#                         /etc/init.d/serclient restart > /dev/null; \
#                     fi;
#         endscript
#     }
# Aruba ExtraControl activation
#     https://admin.dc3.arubacloud.hu/Manage/Serial/SerialActivation.aspx

# node.js
apt-get install -y nodejs
# Make sure packages are installed under /usr/local
npm config -g set prefix "/usr/local"
npm config -g set unicode true
npm install -g less less-plugin-clean-css

# Logrotate periods
#
editor /etc/logrotate.d/rsyslog
#     weekly
#     rotate 15
#     # /var/log/mail.log
#     weekly
#     rotate 15
editor /etc/logrotate.d/apache2
#     daily
#     rotate 90

# Clean up
apt-get autoremove --purge

# Throttle package downloads (1000 kB/s)
echo 'Acquire::Queue-mode "access"; Acquire::http::Dl-Limit "1000";' > /etc/apt/apt.conf.d/76download

# Backup /etc and package configuration
tar cJf "/root/$(hostname -f)_etc-backup_$(date --rfc-3339=date).tar.xz" /etc/
debconf-get-selections > "/root/debconf.selections"
dpkg --get-selections > "/root/packages.selection"

# List of clients and services
cp -v ${D}/server.yml /root/
editor /root/server.yml

# Clear history
history -c
