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
# - Disk access time (~1 ms)
# - CPU speed (2000+ PassMark CPU Mark, sub-20 ms sysbench)
# - Worldwide and regional bandwidth, port speed
# - Spammer neighbours https://www.projecthoneypot.org/ip_1.2.3.4
# - Nightime technical support network or hardware failure response time
# - Daytime technical and billing support
# - D/DoS mitigation
#
# See https://github.com/szepeviktor/wordpress-speedtest/blob/master/README.md#results

# Packages sources
DS_MIRROR="http://cloudfront.debian.net/debian"
#DS_MIRROR="http://http.debian.net/debian"
#DS_MIRROR="http://ftp.COUNTRY-CODE.debian.org/debian"
DS_REPOS="dotdeb nodejs-iojs percona szepeviktor"
#DS_REPOS="deb-multimedia dotdeb mariadb mod-pagespeed mt-aws-glacier \
#    newrelic nginx nodejs-iojs oracle percona postgre szepeviktor varnish"

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
rm -vrf /var/lib/apt/lists/*
apt-get clean
apt-get autoremove --purge -y

# Packages sources
mv -vf /etc/apt/sources.list "/etc/apt/sources.list~"
cp -v ${D}/package/apt-sources/sources.list /etc/apt/
sed -i "s/%MIRROR%/${DS_MIRROR//\//\\/}/g" /etc/apt/sources.list
# Install HTTPS transport
apt-get update
apt-get install -y debian-archive-keyring debian-keyring apt-transport-https
for R in ${DS_REPOS};do cp -v ${D}/package/apt-sources/${R}.list /etc/apt/sources.list.d/;done
eval "$(grep -h -A5 "^deb " /etc/apt/sources.list.d/*.list|grep "^#K: "|cut -d' ' -f2-)"
#editor /etc/apt/sources.list

# APT settings
echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/00languages
echo 'APT::Periodic::Download-Upgradeable-Packages "1";' > /etc/apt/apt.conf.d/20download-upgrade

# Upgrade
apt-get update
apt-get dist-upgrade -y --force-yes
apt-get install -y lsb-release xz-utils ssh sudo ca-certificates most less lftp \
    time bash-completion htop bind9-host mc lynx ncurses-term aptitude iproute2 ipset
ln -svf /usr/bin/host /usr/local/bin/mx

# Input
. /etc/profile.d/bash_completion.sh || Error "bash_completion.sh"
echo "alias e='editor'" > /etc/profile.d/e-editor.sh
sed -i 's/^# \(".*: history-search-.*ward\)$/\1/' /etc/inputrc
update-alternatives --set pager /usr/bin/most
update-alternatives --set editor /usr/bin/mcedit

# Bash
#sed -e 's/\(#.*enable bash completion\)/#\1/' -e '/#.*enable bash completion/,+8 { s/^#// }' -i /etc/bash.bashrc
echo "dash dash/sh boolean false" | debconf-set-selections -v
dpkg-reconfigure -f noninteractive dash

# --- Automated --------------- >8 ------------- >8 ------------
#grep -B1000 "# -\+ Automated -\+" debian-setup.sh
set +e +x
kill -SIGINT $$

# Remove systemd
dpkg -s systemd &> /dev/null && apt-get install -y sysvinit-core sysvinit sysvinit-utils
read -s -p 'Ctrl + D to reboot ' || reboot

apt-get remove -y --purge --auto-remove systemd
echo -e 'Package: *systemd*\nPin: origin ""\nPin-Priority: -1' > /etc/apt/preferences.d/systemd

# Wget defaults
echo -e "\ncontent_disposition = on" >> /etc/wgetrc

# User settings
editor /root/.bashrc

# ---------------------------------------------------------------------

#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

#export IP="$(ip addr show dev xenbr0|sed -n 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p')"
export IP="$(ip addr show dev eth0|sed -n 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p')"

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

export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

export GREP_OPTIONS="--color"
alias grep='grep $GREP_OPTIONS'
alias iotop='iotop -d 0.1 -qqq -o'
alias iftop='NCURSES_NO_UTF8_ACS=1 iftop -nP'
alias transit='xz -9|base64 -w $((COLUMNS-1))'
alias transit-receive='base64 -d|xz -d'
#alias readmail='MAIL=/var/mail/MAILDIR/ mailx'
#     apt-get install -y tcpdump tcpflow
#alias httpdump='tcpdump -nn -i eth0 -s 1500 -l -w - "dst port 80 and dst host ${IP}" | tcpflow -c -r -'

# Colorized man pages with less
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

# Add INI extensions for mc
cp -v /usr/share/mc/syntax/Syntax ~/.config/mc/mcedit/Syntax
sed -i 's;^\(file .*\[nN\]\[iI\]\)\(.*\)$;\1|cf|conf|cnf|local|htaccess\2;' ~/.config/mc/mcedit/Syntax
sed -i 's;^\(file .*(\)py|PY\().*\)$;\1py|PY|yml|yaml\2;' ~/.config/mc/mcedit/Syntax
sed -i 's;^file sources.list\$ sources\\slist$;file (sources)?\\.list$ sources\\slist;' ~/.config/mc/mcedit/Syntax
#editor ~/.config/mc/mcedit/Syntax

# Username
U="viktor"
# GECOS: Full name,Room number,Work phone,Home phone
adduser --gecos "" ${U}
# <<< Enter password twice
K="PUBLIC-KEY"
S="/home/${U}/.ssh";mkdir --mode 700 "$S";echo "$K" >> "${S}/authorized_keys2";chown -R ${U}:${U} "$S"
adduser ${U} sudo
# Expire password
#     passwd -e ${U}

# Change root and other passwords to "*"
editor /etc/shadow
read -s -p "SSH port? " SSH_PORT
# sshd on another port
sed "s/^Port 22$/#Port 22\nPort ${SSH_PORT}/" -i /etc/ssh/sshd_config
# Disable root login
sed 's/^PermitRootLogin yes$/PermitRootLogin no/' -i /etc/ssh/sshd_config
# Disable password login for sudoers
echo -e 'Match Group sudo\n    PasswordAuthentication no' >> /etc/ssh/sshd_config
# Add IP blocking
# See: ${D}/security/README.md
editor /etc/hosts.deny
service ssh restart
netstat -antup|grep sshd

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

# Disk configuration
clear; cat /proc/mdstat; cat /proc/partitions
pvdisplay && vgdisplay && lvdisplay
ls -1 /etc/default/*
head -n 1000 /etc/default/* | grep -vE '^\s*#|^\s*$' | grep --color -A1000 "^==> "

# /tmp in RAM
TOTAL_MEM="$(grep MemTotal /proc/meminfo|sed 's;.*[[:space:]]\([0-9]\+\)[[:space:]]kB.*;\1;')"
[ "$TOTAL_MEM" -gt $((4097 * 1024)) ] && sed -i 's/^#RAMTMP=no$/RAMTMP=yes/' /etc/default/tmpfs

# Mount points
# <file system> <mount point>             <type>          <options>                               <dump> <pass>
clear; editor /etc/fstab
clear; cat /proc/mounts
swapoff -a; swapon -a; cat /proc/swaps

# Create a swap file
dd if=/dev/zero of=/swap0 bs=1M count=768
chmod 0600 /swap0
mkswap /swap0
echo "/swap0    none    swap    sw    0   0" >> /etc/fstab

grep "\S\+\s\+/\s.*relatime" /proc/mounts || echo "ERROR: no relAtime for rootfs"

# Kernel
uname -a
# List kernels
apt-cache policy "linux-image-3.*"
#apt-get install linux-image-amd64=KERNEL-VERSION
clear; ls -l /lib/modules/
ls -latr /boot/
# Verbose boot
sed -i 's/^#*VERBOSE=no$/VERBOSE=yes/' /etc/default/rcS
dpkg -l | grep "grub"
# OVH Kernel "made-in-ovh"
#     https://gist.github.com/szepeviktor/cf6b60ac1b2515cb41c1
# Linode Kernels: auto renew on reboot
#     https://www.linode.com/kernels/
editor /etc/modules
ls -1 /etc/sysctl.d/ | grep -v README.sysctl
editor /etc/sysctl.conf

# Miscellaneous configuration
# Aruba needs arping package in /etc/rc.local
editor /etc/rc.local
editor /etc/profile
ls -l /etc/profile.d/
editor /etc/motd
#     This server is the property of <COMPANY-NAME> Unauthorized entry is prohibited.

# Networking
editor /etc/network/interfaces
#     auto eth0
#     iface eth0 inet static
#         address IP
#         netmask 255.255.255.0
#         #netmask 255.255.254.0
#         gateway GATEWAY
clear; ifconfig -a
route -n -4
route -n -6
netstat -antup

editor /etc/resolv.conf
#     nameserver 8.8.8.8
#     nameserver LOCAL-NS
#     nameserver LOCAL-NS2
#     nameserver 8.8.4.4
#     options timeout:2
#     #options rotate

# Aruba resolvers
#
#     DC1-IT 62.149.128.4 62.149.132.4
#     DC3-CZ 81.2.192.131 81.2.193.227
#
# Vultr resolvers
#
#     Frankfurt 108.61.10.10

clear; ping6 -c 4 ipv6.google.com
host -v -tA example.com|grep "^example\.com\.\s*[0-9]\+\s*IN\s*A\s*93\.184\.216\.34$"||echo "DNS error"
# View network Graph v4/v6
#     http://bgp.he.net/ip/${IP}

# SSL support
rm -f /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key
# Update ca-certificates
#wget -qO- http://metadata.ftp-master.debian.org/changelogs/main/c/ca-certificates/unstable_changelog|less
#Getpkg ca-certificates
# Install szepenet CA
CA_NAME="szepenet"
CA_FILE="szepenet_ca.crt"
mkdir -v /usr/local/share/ca-certificates/${CA_NAME}
cp -v ${D}/security/ca/ca-web/szepenet-ca.pem /usr/local/share/ca-certificates/${CA_NAME}/${CA_FILE}
update-ca-certificates -v -f
# Monitor certificates
cd ${D}; ./install.sh security/cert-expiry.sh

# Block dangerous IP ranges
cd ${D}/security/myattackers-ipsets/
head *.ipset | grep "^#: ip.\+" | cut -d " " -f 2- | /bin/bash

# MYATTACKERS chain
cd ${D} && ./install.sh security/myattackers.sh

# Hostname
# Set A record and PTR record
# Consider: http://www.iata.org/publications/Pages/code-search.aspx
#           http://www.world-airport-codes.com/
read -r -p "Host name? " H
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

# Locale and timezone
clear; locale; locale -a
echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections -v
echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections -v
dpkg-reconfigure -f noninteractive locales
# http://yellerapp.com/posts/2015-01-12-the-worst-server-setup-you-can-make.html
cat /etc/timezone
echo "tzdata tzdata/Zones/Etc select UTC" | debconf-set-selections -v
dpkg-reconfigure -f noninteractive tzdata

# Comment out getty[2-6], NOT /etc/init.d/rc !
# Consider /sbin/agetty
editor /etc/inittab

# Sanitize packages (-hardware-related +monitoring -daemons)
# 1. Delete not-installed packages
clear; dpkg -l|grep -v "^ii"
# 2. Usually unnecessary packages
apt-get purge \
    at ftp dc dbus rpcbind exim4-base exim4-config python2.6-minimal python2.6 \
    lrzsz mlocate rpcbind nfs-common w3m vim-runtime vim-common \
    installation-report debian-faq info install-info manpages man-db texinfo tex-common \
    isc-dhcp-client isc-dhcp-common
deluser Debian-exim
deluser messagebus
# 3. VPS monitoring
ps aux|grep -v "grep"|grep -E "snmp|vmtools|xe-daemon"
dpkg -l|grep -E "xe-guest-utilities|dkms"
# See: ${D}/package/vmware-tools-wheezy.sh
vmware-toolbox-cmd stat sessionid
vmware-uninstall-tools.pl 2>&1 | tee vmware-uninstall.log
rm -vrf /usr/lib/vmware-tools
apt-get install -y open-vm-tools
# 4. Hardware related
dpkg -l|grep -E -w "dmidecode|eject|laptop-detect|usbutils|kbd|console-setup\
|acpid|fancontrol|hddtemp|lm-sensors|sensord|smartmontools|mdadm|popularity-contest"
apt-get purge dmidecode eject laptop-detect usbutils kbd console-setup \
    acpid fancontrol hddtemp lm-sensors sensord smartmontools mdadm popularity-contest
# 5. Non-stable packages
clear; dpkg -l|grep "~[a-z]\+"
dpkg -l|grep -E "~squeeze|~wheezy|python2\.6"
# 6. Non-Debian packages
aptitude search '?narrow(?installed, !?origin(Debian))'
# 7. Obsolete packages
aptitude search '?obsolete'
# 8. Manually installed, not "required" and not "important" packages minus known ones
#wget https://github.com/szepeviktor/debian-server-tools/raw/master/package/debian-jessie-not-req-imp.pkg
aptitude search '?and(?installed, ?not(?automatic), ?not(?priority(required)), ?not(?priority(important)))' -F"%p" \
    | grep -v -x -f ${D}/package/debian-jessie-not-req-imp.pkg | xargs echo
# 9. Development packages
dpkg -l|grep -- "-dev"
# List by section
aptitude search '?and(?installed, ?not(?automatic), ?not(?priority(required)), ?not(?priority(important)))' -F"%s %p"|sort

dpkg -l | most
apt-get autoremove --purge

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
    whois unzip heirloom-mailx iptables-persistent bootlogd goaccess \
    ntpdate apg dos2unix strace ccze mtr-tiny git colordiff gcc libc6-dev make
# Backports
# @wheezy apt-get install -t wheezy-backports -y rsyslog whois git goaccess init-system-helpers

# debsums weekly cron job
sed -i 's/^CRON_CHECK=never.*$/CRON_CHECK=weekly/' /etc/default/debsums

# Check user cron jobs
clear; ${D}/tools/catconf /etc/crontab /var/spool/cron/crontabs/*

# Automatic package updates
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true"|debconf-set-selections -v
dpkg-reconfigure -f noninteractive unattended-upgrades

# Sanitize files
rm -vrf /var/lib/clamav /var/log/clamav
read -r -p "Hosting company? " HOSTING_COMPANY
find / -iname "*${HOSTING_COMPANY}*"
grep -ir "${HOSTING_COMPANY}" /etc/
dpkg -l | grep -i "${HOSTING_COMPANY}"

# /root/dist-mod
cd /root/; mkdir dist-mod && cd dist-mod/

# Modified files
cruft --ignore /dev | tee cruft.log
# Find broken symlinks
find / -type l -xtype l -not -path "/proc/*"
debsums --all --changed | tee debsums-changed.log
# Check MD5 sums for installed packages
#for L in /var/lib/dpkg/info/*.list;do P=$(basename "$L" .list);[ -r "/var/lib/dpkg/info/${P}.md5sums" ]||echo "$P";done

# Custom APT repositories
editor /etc/apt/sources.list.d/others.list && apt-get update

# Get pip
apt-get install -y python3-dev
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
python2 get-pip.py

# Detect if we are running in a virtual machine
apt-get install -y virt-what
virt-what
apt-get purge dmidecode virt-what

# rsyslogd immark plugin
#     http://www.rsyslog.com/doc/rsconf1_markmessageperiod.html
editor /etc/rsyslog.conf
#     $ModLoad immark
#     $MarkMessagePeriod 1800
service rsyslog restart

# Debian tools
cd /usr/local/src/ && git clone --recursive https://github.com/szepeviktor/debian-server-tools.git
D="$(pwd)/debian-server-tools"
rm -vrf /root/src/debian-server-tools-master/
cd ${D}; ls tools/ | xargs -I "%%" ./install.sh tools/%%

# CPU
grep -E "model name|cpu MHz|bogomips" /proc/cpuinfo
cd /root/; wget https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/plain/arch/x86/include/asm/cpufeature.h
for FLAG in $(grep -m1 "^flags" /proc/cpuinfo|cut -d":" -f2-); do echo -n "$FLAG"
 grep -C1 "^#define X86_\(FEATURE\|BUG\)_" cpufeature.h \
 | grep -i -m1 "/\* \"${FLAG}\"\|^#define X86_\(FEATURE\|BUG\)_${FLAG}" \
 | grep -o './\*.*\*/' || echo "N/A"; done
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# Performance mode
#     for SG in /sys/devices/system/cpu/*/cpufreq/scaling_governor;do echo "performance">$SG;done

# Entropy - check virtio_rng on KVM
cat /sys/devices/virtual/misc/hw_random/rng_available
cat /sys/devices/virtual/misc/hw_random/rng_current
[ -c /dev/hwrng ] && apt-get install -y rng-tools
# Software based entropy source
apt-get install -y haveged
cat /proc/sys/kernel/random/entropy_avail

# IRQ balance
declare -i CPU_COUNT="$(grep -c "^processor" /proc/cpuinfo)"
[ "$CPU_COUNT" -gt 1 ] && apt-get install -y irqbalance && cat /proc/interrupts

# Make cron log all failed jobs (exit status != 0)
sed -i "s/^#\s*\(EXTRA_OPTS='-L 5'\)/\1/" /etc/default/cron || echo "ERROR: cron-default"
service cron restart

# Time synchronization
cd ${D}; ./install.sh monitoring/ntpdated
editor /etc/default/ntpdate
# http://support.ntp.org/bin/view/Servers/StratumTwoTimeServers
# Set nearest time server: http://www.pool.ntp.org/en/
#     NTPSERVERS="0.uk.pool.ntp.org 1.uk.pool.ntp.org 2.uk.pool.ntp.org 3.uk.pool.ntp.org"
#     NTPSERVERS="0.de.pool.ntp.org 1.de.pool.ntp.org 2.de.pool.ntp.org 3.de.pool.ntp.org"
#     NTPSERVERS="0.fr.pool.ntp.org 1.fr.pool.ntp.org 2.fr.pool.ntp.org 3.fr.pool.ntp.org"
#     NTPSERVERS="0.cz.pool.ntp.org 1.cz.pool.ntp.org 2.cz.pool.ntp.org 3.cz.pool.ntp.org"
#     NTPSERVERS="0.hu.pool.ntp.org 1.hu.pool.ntp.org 2.hu.pool.ntp.org 3.hu.pool.ntp.org"
# OVH
#     NTPSERVERS="ntp.ovh.net"

# µnscd
apt-get install -y unscd
editor /etc/nscd.conf
#     enable-cache            hosts   yes
#     positive-time-to-live   hosts   60
#     negative-time-to-live   hosts   20
service unscd stop && service unscd start

# VPS check
cd ${D}; ./install.sh monitoring/vpscheck.sh
editor /usr/local/sbin/vpscheck.sh
vpscheck.sh -gen
editor /root/.config/vpscheck/configuration
#editor /usr/local/sbin/vpscheck.sh
# Test run
vpscheck.sh

# msmtp
apt-get install -y msmtp-mta
# /usr/share/doc/msmtp/examples/msmtprc-system.example
cp -vf ${D}/mail/msmtprc /etc/
# Configure Mandrill
#     https://www.mandrill.com/signup/
#     http://msmtp.sourceforge.net/doc/msmtp.html
echo "This is a test mail."|mailx -s "[first] Subject of the first email" ADDRESS

# Courier MTA - deliver all mail to a smarthost
#     Send-only servers don't receive emails.
#     Send-only servers don't have local domain names.
#     They should have an MX record pointing to the smarthost.
#     Smarthost should receive all emails addressed to send-only server's domain name.
clear; apt-get install -y courier-mta courier-mta-ssl
# Fix dependency on courier-authdaemon
sed -i '1,20s/^\(#\s\+Required-Start:\s.*\)$/\1 courier-authdaemon/' /etc/init.d/courier-mta
update-rc.d courier-mta defaults
# Check for other MTA-s
dpkg -l | grep -E "postfix|exim"
cd ${D}; ./install.sh mail/courier-restart.sh
# Smarthost
editor /etc/courier/esmtproutes
#     : %SMART-HOST%,587 /SECURITY=REQUIRED
#     : smtp.mandrillapp.com,587 /SECURITY=REQUIRED
# From jessie on - requires ESMTP_TLS_VERIFY_DOMAIN=1 and TLS_VERIFYPEER=PEER
#     : %SMART-HOST%,465 /SECURITY=SMTPS
editor /etc/courier/esmtpauthclient
#     smtp.mandrillapp.com,587 MANDRILL@ACCOUNT API-KEY
openssl dhparam -out /etc/courier/dhparams.pem 2048
editor /etc/courier/esmtpd
#     TLS_DHPARAMS=/etc/courier/dhparams.pem
#     ADDRESS=127.0.0.1
#     TCPDOPTS=" ... ... -noidentlookup"
#     ESMTPAUTH=""
#     ESMTPAUTH_TLS=""
editor /etc/courier/esmtpd-ssl
#     SSLADDRESS=127.0.0.1
#     TLS_DHPARAMS=/etc/courier/dhparams.pem
editor /etc/courier/smtpaccess/default
#     127.0.0.1	allow,RELAYCLIENT
#     :0000:0000:0000:0000:0000:0000:0000:0001	allow,RELAYCLIENT
editor /etc/courier/me
# Check MX record
host -t MX $(cat /etc/courier/me)
editor /etc/courier/defaultdomain
# SPF - Add this server to the SPF record of its domains
editor /etc/courier/dsnfrom
editor /etc/courier/locals
#     localhost
#     # Remove own hostname!
editor /etc/courier/aliases/system
#     postmaster: |/usr/bin/couriersrs --srsdomain=DOMAIN.SRS admin@szepe.net
courier-restart.sh
# Allow unauthenticated SMTP traffic from this server on the smarthost
#     editor /etc/courier/smtpaccess/default
#         %%IP%%<TAB>allow,RELAYCLIENT,AUTH_REQUIRED=0

# Receive bounce messages on the smarthost
#     editor /etc/courier/aliases/system
#         @HOSTNAME.TLD: LOCAL-USER
#     editor /var/mail/DOMAIN/USER/.courier-default
#         LOCAL-USER
#     courier-restart.sh
echo "This is a t3st mail."|mailx -s "[first] Subject of the 1st email" viktor@szepe.net

# Apache 2.4 with ITK
# @wheezy apt-get install -y -t wheezy-experimental apache2-mpm-itk apache2-utils libapache2-mod-fastcgi
apt-get install -y apache2-mpm-itk apache2-utils

# Apache 2.4 with mpm-events
apt-get install -y apache2 apache2-utils
adduser --disabled-password --gecos "" web
editor /etc/apache2/evvars
#     export APACHE_RUN_USER=web
#     export APACHE_RUN_GROUP=web

a2enmod actions rewrite headers deflate expires proxy_fcgi
# Comment out '<Location /server-status>' block
editor /etc/apache2/mods-available/status.conf
a2enmod ssl
mkdir /etc/apache2/ssl && chmod 750 /etc/apache2/ssl
cp -v ${D}/webserver/apache-conf-available/* /etc/apache2/conf-available/
yes|cp -vf ${D}/webserver/apache-sites-available/* /etc/apache2/sites-available/
echo -e "User-agent: *\nDisallow: /\n" > /var/www/html/robots.txt

# Use php-fpm.conf settings per site
a2enconf h5bp
editor /etc/apache2/conf-enabled/security.conf
#     ServerTokens Prod
editor /etc/apache2/apache2.conf
#     LogLevel info
# @TODO fcgi://port,path?? ProxyPassMatch "^/.*\.php$" "unix:/var/run/php5-fpm.sock|fcgi://127.0.0.1:9000/var/www/website/html"

# mod_pagespeed for poorly written websites
apt-get install -y mod-pagespeed-stable
# Remove duplicate
ls -l /etc/apt/sources.list.d/*pagespeed*
#rm -v /etc/apt/sources.list.d/mod-pagespeed.list

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
Getpkg geoip-database-contrib
apt-get install -y geoip-bin recode python3-pyinotify
#     apt-get install -y fail2ban
Getpkg fail2ban
mc ${D}/security/fail2ban-conf/ /etc/fail2ban/
# Config:    fail2ban.local
# Jails:     jail.local
# /filter.d: apache-combined.local, apache-instant.local, courier-smtp.local, recidive.local
# /action.d: cloudflare.local
service fail2ban restart

# PHP 5.6
apt-get install -y php5-apcu php5-cli php5-curl php5-fpm php5-gd \
    php5-mcrypt php5-mysqlnd php5-readline php5-sqlite php-pear php5-dev
PHP_TZ="$(head -n 1 /etc/timezone)"
sed -i 's/^expose_php = .*$/expose_php = Off/' /etc/php5/fpm/php.ini
sed -i 's/^max_execution_time = .*$/max_execution_time = 65/' /etc/php5/fpm/php.ini
sed -i 's/^memory_limit = .*$/memory_limit = 384M/' /etc/php5/fpm/php.ini
sed -i 's/^post_max_size = .*$/post_max_size = 20M/' /etc/php5/fpm/php.ini
sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 20M/' /etc/php5/fpm/php.ini
sed -i 's/^allow_url_fopen = .*$/allow_url_fopen = Off/' /etc/php5/fpm/php.ini
sed -i "s|^;date.timezone =.*\$|date.timezone = ${PHP_TZ}|" /etc/php5/fpm/php.ini
# Only Prg site is allowed
sed -i 's|^;opcache.restrict_api\s*=.*$|opcache.restrict_api = /home/web/website/|' /etc/php5/fpm/php.ini
sed -i 's/^;opcache.memory_consumption\s*=.*$/opcache.memory_consumption = 256/' /etc/php5/fpm/php.ini
sed -i 's/^;opcache.interned_strings_buffer\s*=.*$/opcache.interned_strings_buffer = 16/' /etc/php5/fpm/php.ini

# OPcache - There may be more than 10k files
#     find /home/ -type f -name "*.php"|wc -l
sed -i 's/^;opcache.max_accelerated_files\s*=.*$/opcache.max_accelerated_files = 10000/' /etc/php5/fpm/php.ini
# APCu
echo -e "\n[apc]\napc.enabled = 1\napc.shm_size = 64M" >> /etc/php5/fpm/php.ini

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
# - FastCGI -idle-timeout
# - PHP-FPM pool request_terminate_timeout

# Suhosin extension
#     https://github.com/stefanesser/suhosin/releases
apt-get install -y php5-suhosin-extension
php5enmod -s fpm suhosin
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

# PHP 7.0
apt-get install -y php7.0-cli php7.0-fpm \
    php7.0-curl php7.0-gd php7.0-json php7.0-intl php7.0-mysql php7.0-readline php7.0-sqlite3
# php7.0-mcrypt compiled in
PHP_TZ="Europe/Budapest"
sed -i 's/^expose_php = .*$/expose_php = Off/' /etc/php/7.0/fpm/php.ini
sed -i 's/^max_execution_time = .*$/max_execution_time = 65/' /etc/php/7.0/fpm/php.ini
sed -i 's/^memory_limit = .*$/memory_limit = 384M/' /etc/php/7.0/fpm/php.ini
sed -i 's/^post_max_size = .*$/post_max_size = 20M/' /etc/php/7.0/fpm/php.ini
sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 20M/' /etc/php/7.0/fpm/php.ini
sed -i 's/^allow_url_fopen = .*$/allow_url_fopen = Off/' /etc/php/7.0/fpm/php.ini
sed -i "s|^;date.timezone =.*\$|date.timezone = ${PHP_TZ}|" /etc/php/7.0/fpm/php.ini
# Only Prg site is allowed
sed -i 's/^;opcache.memory_consumption\s*=.*$/opcache.memory_consumption = 256/' /etc/php/7.0/fpm/php.ini
sed -i 's/^;opcache.interned_strings_buffer\s*=.*$/opcache.interned_strings_buffer = 16/' /etc/php/7.0/fpm/php.ini
sed -i 's|^;opcache.restrict_api\s*=.*$|opcache.restrict_api = /home/web/website/|' /etc/php/7.0/fpm/php.ini

# OPcache - There may be more than 10k files
#     find /home/ -type f -name "*.php"|wc -l
sed -i 's/^;opcache.max_accelerated_files\s*=.*$/opcache.max_accelerated_files = 10000/' /etc/php5/fpm/php.ini
# APCu
echo -e "\n[apc]\napc.enabled = 1\napc.shm_size = 64M" >> /etc/php5/fpm/php.ini

# @TODO Measure: realpath_cache_size = 16k  realpath_cache_ttl = 120
#       https://www.scalingphpbook.com/best-zend-opcache-settings-tuning-config/

grep -Ev "^\s*#|^\s*;|^\s*$" /etc/php/7.0/fpm/php.ini | most
# Disable "www" pool
mv /etc/php/7.0/fpm/pool.d/www.conf /etc/php/7.0/fpm/pool.d/www.conf.default
cp -v ${D}/webserver/phpfpm-pools/* /etc/php/7.0/fpm/
# PHP session cleaning
#/usr/lib/php/sessionclean

# @FIXME PHP timeouts
# - PHP max_execution_time
# - PHP max_input_time
# - FastCGI -idle-timeout
# - PHP-FPM pool request_terminate_timeout

# Suhosin extension
#     https://github.com/stefanesser/suhosin/releases
apt-get install -y php5-suhosin-extension
php5enmod -s fpm suhosin
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
cd ${D}; ./install.sh webserver/webrestart.sh

# Add the development website
# See: ${D}/webserver/add-prg-site.sh

# Add a production website
# See: ${D}/webserver/add-site.sh

# MariaDB
apt-get install -y mariadb-server-10.0 mariadb-client-10.0
read -e -p "MYSQL_PASSWORD? " MYSQL_PASSWORD
echo -e "[mysql]\nuser=root\npass=${MYSQL_PASSWORD}\ndefault-character-set=utf8" >> /root/.my.cnf
echo -e "[mysqldump]\nuser=root\npass=${MYSQL_PASSWORD}\ndefault-character-set=utf8" >> /root/.my.cnf
chmod 600 /root/.my.cnf
#editor /root/.my.cnf

# WP-CLI
WPCLI_URL="https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
wget -O /usr/local/bin/wp "$WPCLI_URL" && chmod -c +x /usr/local/bin/wp
WPCLI_COMPLETION_URL="https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash"
wget -O- "$WPCLI_COMPLETION_URL"|sed 's/wp cli completions/wp --allow-root cli completions/' > /etc/bash_completion.d/wp-cli
# If you have suhosin in global php5 config
#     grep "[^;#]*suhosin\.executor\.include\.whitelist.*phar" /etc/php5/cli/conf.d/*suhosin*.ini || Error "Whitelist phar"

# Drush
#     https://github.com/drush-ops/drush/releases
wget -qO getcomposer.php https://getcomposer.org/installer
php getcomposer.php --install-dir=/usr/local/bin --filename=composer
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
# See: ${D}/webserver/preload-cache.sh

# Spamassassin
apt-get install -y libmail-dkim-perl \
    libsocket6-perl libsys-hostname-long-perl libnet-dns-perl libnetaddr-ip-perl \
    libcrypt-openssl-rsa-perl libdigest-hmac-perl libio-socket-inet6-perl libnet-ip-perl \
    libcrypt-openssl-bignum-perl
Getpkg spamassassin

# SSL certificate for web, mail etc.
# See: ${D}/security/new-ssl-cert.sh

# Test TLS connections
# See: ${D}/security/README.md

# ProFTPD
# When the default locale for your system is not en_US.UTF-8
# be sure to add this to /etc/default/proftpd for fail2ban to understand dates.
#     export LC_TIME="en_US.UTF-8"

# Simple syslog monitoring
apt-get install -y libdate-manip-perl
DGR="$(wget -qO- https://api.github.com/repos/mdom/dategrep/releases|sed -n '0,/^.*"tag_name": "\([0-9.]\+\)".*$/{s//\1/p}')" #'
wget -O /usr/local/bin/dategrep https://github.com/mdom/dategrep/releases/download/${DGR}/dategrep-standalone-small
chmod -c +x /usr/local/bin/dategrep
cd ${D}; ./install.sh monitoring/syslog-errors.sh

# Monit - monitoring
#     https://packages.debian.org/sid/amd64/monit/download
apt-get install -y monit
# See: ${D}/monitoring/monit/
#     https://mmonit.com/monit/documentation/monit.html
service monit restart
# Wait for start
tail -f /var/log/monit.log
monit summary
lynx 127.0.0.1:2812

# Munin - network-wide graphing
# See: ${D}/monitoring/munin/munin-debian-setup.sh

# Aruba ExtraControl (serclient)
#     http://admin.dc3.arubacloud.hu/Manage/Serial/SerialManagement.aspx
wget -nv https://admin.dc3.arubacloud.hu/Installers/debian/aruba-serclient_0.01-1_all.deb
dpkg -i aruba-serclient_*_all.deb
# Set log level
echo -e "[LOG]\nlevel = 20" >> /opt/serclient/serclient.ini
# Comment out "if getRestartGUID(remove=False) == None: rf.doRollover()"
editor /opt/serclient/tools.py:159
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
# Activate ExtraControl
#     https://admin.dc3.arubacloud.hu/Manage/Serial/SerialActivation.aspx

# node.js
apt-get install -y iojs
# Install packaged under /usr/local/
npm config set prefix=/usr/local/
npm install -g less
npm install -g less-plugin-clean-css

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

# Backup /etc
tar cJf "/root/$(hostname -f)_etc-backup_$(date --rfc-3339=date).tar.xz" /etc/

# Clients and services
cp -v ${D}/server.yml /root/
editor /root/server.yml
