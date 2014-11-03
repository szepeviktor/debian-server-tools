#!/bin/bash
#
# Debian setup (wheezy amd64).
# Not a script but a manual.
#
# Some OVH VPS tips like: /etc/ovhrc


# identify distribution
lsb_release -a

# clean packages
apt-get clean
apt-get autoremove --purge -y

# packages sources
nano /etc/apt/sources.list
# OVH's local mirror: http://debian.mirrors.ovh.net/debian
# server4you: http://debian.intergenia.de/debian
# closest mirror http://http.debian.net/debian
# national mirror: http://ftp.<COUNTRY-CODE>.debian.org/debian
deb <MIRROR> wheezy  main contrib non-free
# security
deb http://security.debian.org/ wheezy/updates  main contrib non-free
# updates (previously known as 'volatile')
deb <MIRROR> wheezy-updates  main
# backports
# http://backports.debian.org/changes/wheezy-backports.html
deb <MIRROR> wheezy-backports  main

# upgrade
apt-get update
apt-get dist-upgrade -y
apt-get install -y ssh mc most ca-certificates lftp bash-completion sudo htop bind9-host ncurses-term

# input
echo "alias e='mcedit'" > /etc/profile.d/editor.sh || echo "ERROR: alias 'e'"
sed -i 's/^# \(".*: history-search-.*ward\)$/\1/' /etc/inputrc || echo "ERROR: history-search-backward"
sed -e 's/\(#.*enable bash completion\)/#\1/' -e '/#.*enable bash completion/,+8 { s/^#// }' -i /etc/bash.bashrc || echo "ERROR: bash completion"
update-alternatives --set pager /usr/bin/most
update-alternatives --set editor /usr/bin/mcedit

# bash as default shell
echo "dash dash/sh boolean false"|debconf-set-selections -v
dpkg-reconfigure -f noninteractive dash

# bashrc
nano /root/.bashrc
export PS1="[\[$(tput setaf 3)\]\u\[\033[1;31m\]@\h\[$(tput sgr0)\]:\[$(tput setaf 8)\]\[$(tput setab 4)\]\w\[$(tput sgr0)\]:\t:\[$(tput setaf 0)\]\!\[$(tput sgr0)\]]\n"
# ls -1 /usr/share/mc/skins/
export MC_SKIN='modarin256root-defbg'
export GREP_OPTIONS='--color'
alias grep='grep $GREP_OPTIONS'

# user
adduser viktor
# enter password...
K="<PUBLIC-KEY>"
S="/home/viktor/.ssh"; mkdir --mode 700 "$S"; echo "$K" >> "${S}/authorized_keys2"; chown -R viktor:viktor "$S"
adduser viktor sudo

# remove root password
nano /etc/shadow
# ssh on port 3022
sed 's/^Port 22$/#Port 22\nPort 3022/' -i /etc/ssh/sshd_config
service ssh restart
netstat -antp|grep sshd

# log out as root
logout

# log in
sudo su - || exit

# hardware
lspci
[ -f /proc/modules ] && lsmod || echo "WARNING: monolithic kernel"

# disk configuration
cat /proc/mdstat
cat /proc/partitions
cat /proc/mounts
cat /proc/swaps
grep "relatime" /proc/mounts || echo "ERROR: no relAtime"

# kernel
uname -a
dpkg -l|grep "grub"
ls -ltr /boot/
# OVH Kernel
#cd /boot/; lftp -e "mget *-xxxx-grs-ipv6-64-vps; bye" ftp://ftp.ovh.net/made-in-ovh/bzImage/latest-production/

# network
netstat -antp
ifconfig
route -n -4
route -n -6
ping6 ipv6.google.com
e /etc/network/interfaces
e /etc/resolv.conf
#nameserver 8.8.8.8
#nameserver 8.8.4.4
#nameserver <LOCAL_NS>
#options timeout:2
host -v -t A example.com

# hostname
# set A record and PTR record
H="<HOST-NAME>"
grep -ir "$(hostname)" /etc/
hostname "$H"
echo "$H" > /etc/hostname
e /etc/hosts

# locale
dpkg-reconfigure locales

# comment out getty[2-6], not init.d/rc !
e /etc/inittab
# sanitize users
e /etc/passwd

# sanitize packages (-hardware-related +monitoring -daemons)
# delete not installed packages
dpkg -l|grep -v "^ii"
# apt-get purge
# non-stable packages
dpkg -l|grep "~[a-z]\+"|sort|uniq -c|sort -n
#dpkg -l|grep "~squeeze"
# vps monitoring
ps aux|grep -v "grep"|egrep "snmp|vmtools|xe-daemon"
# see: package/vmware-tools-wheezy.sh
dpkg -l|most
# dpkg -l|egrep "fancontrol|acpid|laptop-detect|lm-sensors|sensord|smartmontools|mdadm|lvm|usbutils"
# sanitize files
apt-get autoremove --purge

# essential packages
apt-get install -y unattended-upgrades apt-listchanges cruft debsums ntpdate gcc make colordiff
apt-get install -t wheezy-backports -y rsyslog whois git
cd /root/; git clone https://github.com/szepeviktor/debian-server-tools.git

# IRQ balance
declare -i CPU_COUNT="$(grep -c "^processor" /proc/cpuinfo)"
[ "$CPU_COUNT" -gt 1 ] && apt-get install -y irqbalance && cat /proc/interrupts

# time
dpkg-reconfigure tzdata
# see: monitoring/ntpdated
# set nearest time server
e /etc/default/ntpdate

# backported unscd
wget http://mirror.szepe.net/debian/pool/main/u/unscd/unscd_0.51-1~bpo70+1_amd64.deb
dpkg -i unscd_*_amd64.deb
e /etc/nscd.conf
# enable-cache            hosts   yes
# positive-time-to-live   hosts   60
# negative-time-to-live   hosts   20

# non-package files
find / -iname "*<HOSTING-COMPANY>*"
cruft --ignore /dev/|tee cruft.log
debsums -c

# updates
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true"|debconf-set-selections -v
dpkg-reconfigure -f noninteractive unattended-upgrades

# detect whether your container is running under a hypervisor
wget -O slabbed-or-not.zip https://github.com/kaniini/slabbed-or-not/archive/master.zip
unzip slabbed-or-not.zip && rm slabbed-or-not.zip
cd slabbed-or-not-master/
make && ./slabbed-or-not|tee ../slabbed-or-not.log

# VPS check
mv monitoring/vpscheck.sh /usr/local/sbin/vpscheck.sh
vpscheck.sh -gen
install-cron.sh /usr/local/sbin/vpscheck.sh

# fail2ban latest version's .dsc: https://tracker.debian.org/pkg/fail2ban
apt-get install -y geoip-database-contrib geoip-bin recode python3-pyinotify
apt-get install -t wheezy-backports -y init-system-helpers
dget -ux <DSC-URL>
dpkg-checkbuilddeps && dpkg-buildpackage -b -us -uc
# 0.9.1: wget http://mirror.szepe.net/debian/pool/main/f/fail2ban/fail2ban_0.9.1-1_all.deb
dpkg -i --dry-run <PACKAGE>
dpkg -i <PACKAGE>
e /etc/fail2ban/jail.local

# repositories for these softwares
# see package/README.md

# Apache 2.4.x (jessie backport)
apt-get install -y apache2-mpm-itk

# PHP 5.5 from DotDeb
apt-get install -y php-pear php5-apcu php5-cgi php5-cli php5-curl php5-dev php5-fpm php5-gd \
    php5-mcrypt php5-mysqlnd php5-readline php5-sqlite pkg-php-tools

# opcache, APC control panel
cp webserver/ocp.php <DEVELOPMENT-DOCUMENT-ROOT>
APC_URL="http://pecl.php.net/get/APC-3.1.13.tgz"
wget -qO- "$APC_URL" | tar xz --no-anchored apc.php && mv APC*/apc.php <DEVELOPMENT-DOCUMENT-ROOT> && rmdir APC*

# suhosin: https://github.com/stefanesser/suhosin/releases
SUHOSIN_URL="<RELEASE-TAR-GZ>"
tar xf "$SUHOSIN_URL" && cd suhosin-*
phpize && ./configure && make && make test || echo "ERROR: suhosin build failed."
make install && cp -v suhosin.ini /etc/php5/fpm/conf.d/00-suhosin.ini

# wp-cli
WPCLI_URL="https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
wget -O /usr/local/bin/wp "$WPCLI_URL" && chmod +x /usr/local/bin/wp
WPCLI_COMPLETION_URL="https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash"
wget -O- "$WPCLI_COMPLETION_URL" && sed 's/wp cli completions/wp --allow-root cli completions/' > /etc/bash_completion.d/wp-cli
# if you use the suhosin patch
grep "[^;#]*suhosin\.executor\.include\.whitelist.*phar" /etc/php5/cli/conf.d/suhosin*.ini || echo "Please enable phar in suhosin!"

# drush - https://github.com/drush-ops/drush/releases
composer global require drush/drush:6.*
# set up a Druapl site
sudo -u <SITE-USER> -i -- drush --root=<DOCUMENT_ROOT> vset --yes file_private_path "<PRIVATE-PATH>"
sudo -u <SITE-USER> -i -- drush --root=<DOCUMENT_ROOT> vset --yes file_temporary_path "<TEMP_DIRECTORY>"
sudo -u <SITE-USER> -i -- drush --root=<DOCUMENT_ROOT> vset --yes cron_safe_threshold 0

# colorized man with less
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
            man "$@"
}
