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
# Linode: http://mirrors.linode.com/debian
# OVH: http://debian.mirrors.ovh.net/debian
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
apt-get install -y ssh sudo ca-certificates most lftp bash-completion htop bind9-host mc ncurses-term

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
export PS1="[\[$(tput setaf 3)\]\u\[\033[1;31m\]@\h\[$(tput sgr0)\]:\[$(tput setaf 8)\]\[$(tput setab 4)\]\
\w\[$(tput sgr0)\]:\t:\[$(tput setaf 0)\]\!\[$(tput sgr0)\]]\n"
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
ls -latr /boot/
# OVH Kernel
#cd /boot/; lftp -e "mget *-xxxx-grs-ipv6-64-vps; bye" ftp://ftp.ovh.net/made-in-ovh/bzImage/latest-production/
# Linode Kernels
# auto renew - https://www.linode.com/kernels/
e /etc/motd

# network
netstat -antup
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
##options rotate
host -v -t A example.com
# view network graph: http://bgp.he.net/ip/<IP>

# hostname
# set A record and PTR record
# consider: http://www.iata.org/publications/Pages/code-search.aspx
#           http://www.world-airport-codes.com/
H="<HOST-NAME>"
grep -ir "$(hostname)" /etc/
hostname "$H"
echo "$H" > /etc/hostname
e /etc/hosts

# locale, timezone
dpkg-reconfigure locales
dpkg-reconfigure tzdata

# comment out getty[2-6], not init.d/rc !
# consider agetty
e /etc/inittab
# sanitize users
e /etc/passwd
e /etc/shadow

# sanitize packages (-hardware-related +monitoring -daemons)
# delete not installed packages
dpkg -l|grep -v "^ii"
# apt-get purge isc-dhcp-client isc-dhcp-common python2.6-minimal python2.6 rpcbind nfs-common
# non-stable packages
dpkg -l|grep "~[a-z]\+"|sort|uniq -c|sort -n
#dpkg -l|grep "~squeeze"
# vps monitoring
ps aux|grep -v "grep"|egrep "snmp|vmtools|xe-daemon|rpc"
# see: package/vmware-tools-wheezy.sh
dpkg -l|egrep "fancontrol|acpid|laptop-detect|eject|lm-sensors|sensord|smartmontools|mdadm|lvm|usbutils"
dpkg -l|most
apt-get autoremove --purge

# essential packages
apt-get install -y heirloom-mailx unattended-upgrades apt-listchanges cruft debsums ntpdate gcc make colordiff pwgen
apt-get install -t wheezy-backports -y rsyslog whois git
cd /root/; git clone https://github.com/szepeviktor/debian-server-tools.git

# IRQ balance
declare -i CPU_COUNT="$(grep -c "^processor" /proc/cpuinfo)"
[ "$CPU_COUNT" -gt 1 ] && apt-get install -y irqbalance && cat /proc/interrupts

# time
./install-cron.sh monitoring/ntpdated
# set nearest time server: http://www.pool.ntp.org/en/
e /etc/default/ntpdate

# measure CPU speed bz2 25MB, disk access time and throughput hdd-, network speed multiple connections
# https://github.com/mgutz/vpsbench/blob/master/vpsbench

# backported unscd
wget http://mirror.szepe.net/debian/pool/main/u/unscd/unscd_0.51-1~bpo70+1_amd64.deb
dpkg -i unscd_*_amd64.deb
e /etc/nscd.conf
# enable-cache            hosts   yes
# positive-time-to-live   hosts   60
# negative-time-to-live   hosts   20
service unscd restart

# sanitize files
HOSTING_COMPANY="<HOSTING-COMPANY>"
find / -iname "*${HOSTING_COMPANY}*"
grep -ir "${HOSTING_COMPANY}" /etc/
dpkg -l|grep -i "${HOSTING_COMPANY}"
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
#FIXMe install.sh ...
cp -v monitoring/vpscheck.sh /usr/local/sbin/vpscheck.sh
vpscheck.sh -gen
./install-cron.sh /usr/local/sbin/vpscheck.sh

# fail2ban latest version's .dsc: https://tracker.debian.org/pkg/fail2ban
apt-get install -y geoip-bin recode python3-pyinotify
apt-get install -t wheezy-backports -y init-system-helpers
# latest geoip-database-contrib version
wget http://ftp.de.debian.org/debian/pool/contrib/g/geoip-database-contrib/geoip-database-contrib_1.17_all.deb
dpkg -i geoip-database-contrib_*.deb
# .dsc from sid: https://packages.debian.org/sid/fail2ban
dget -ux <DSC-URL>
dpkg-checkbuilddeps && dpkg-buildpackage -b -us -uc
#wget http://mirror.szepe.net/debian/pool/main/f/fail2ban/fail2ban_0.9.1-1_all.deb
dpkg -i --dry-run fail2ban_*.deb
dpkg -i fail2ban_*.deb
# filter: apache-combined
# action: sendmail-geoip-lines.local
e /etc/fail2ban/jail.local

# apt repositories for these softwares
# see package/README.md
apt-get update

# Apache 2.4.x (jessie backport)
apt-get install -y -t wheezy-experimental apache2-mpm-itk apache2-utils
wget http://mirror.szepe.net/debian/pool/main/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1byte3_amd64.deb
dpkg -i libapache2-mod-fastcgi_2.4*.deb
a2enmod actions
a2enmod rewrite
a2enmod headers
a2enmod deflate
a2enmod expires
# chmod 750 public_html/server

# PHP 5.5 from DotDeb
apt-get install -y php-pear php5-apcu php5-cgi php5-cli php5-curl php5-dev php5-fpm php5-gd \
    php5-mcrypt php5-mysqlnd php5-readline php5-sqlite
# ??? pkg-php-tools
e /etc/php5/fpm/php.ini
#expose_php = Off
#max_execution_time = 65
#memory_limit = 384M
#upload_max_filesize = 20M
#allow_url_fopen = Off


# opcache, APC control panel
cp -v webserver/ocp.php <DEVELOPMENT-DOCUMENT-ROOT>
APC_URL="http://pecl.php.net/get/APC-3.1.13.tgz"
wget -qO- "$APC_URL" | tar xz --no-anchored apc.php && mv APC*/apc.php <DEVELOPMENT-DOCUMENT-ROOT> && rmdir APC*

# for poorly written themes/plugins
apt-get install -y mod-pagespeed-stable

# suhosin: https://github.com/stefanesser/suhosin/releases
SUHOSIN_URL="<RELEASE-TAR-GZ>"
wget -qO- "$SUHOSIN_URL"|tar xz && cd suhosin-suhosin-*
phpize && ./configure && make && make test || echo "ERROR: suhosin build failed."
make install && cp -v suhosin.ini /etc/php5/fpm/conf.d/00-suhosin.ini && cd ..

# wp-cli
WPCLI_URL="https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
wget -O /usr/local/bin/wp "$WPCLI_URL" && chmod +x /usr/local/bin/wp
WPCLI_COMPLETION_URL="https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash"
wget -O- "$WPCLI_COMPLETION_URL"|sed 's/wp cli completions/wp --allow-root cli completions/' > /etc/bash_completion.d/wp-cli
# if you have suhosin in global php5 config
#grep "[^;#]*suhosin\.executor\.include\.whitelist.*phar" /etc/php5/cli/conf.d/suhosin*.ini || echo "Please enable phar in suhosin!"

wget -qO "getcomposer.php" https://getcomposer.org/installer
php "getcomposer.php" --install-dir=/usr/local/bin --filename=composer
# drush - https://github.com/drush-ops/drush/releases
mkdir -p /opt/drush && cd /opt/drush
composer require drush/drush:6.*
ln -sv /opt/drush/vendor/bin/drush /usr/local/bin/drush
# set up a Drupal site
#sudo -u <SITE-USER> -i -- drush --root=<DOCUMENT_ROOT> vset --yes file_private_path "<PRIVATE-PATH>"
#sudo -u <SITE-USER> -i -- drush --root=<DOCUMENT_ROOT> vset --yes file_temporary_path "<TEMP_DIRECTORY>"
#sudo -u <SITE-USER> -i -- drush --root=<DOCUMENT_ROOT> vset --yes cron_safe_threshold 0

# MariaDB
apt-get install -y mariadb-server-10.0 mariadb-client-10.0
echo -e "[mysql]\nuser=root\npass=<PASSWORD>" >> /root/.my.cnf && chmod 600 /root/.my.cnf
# for PHPMyAdmin see: package/phpmyadmin-get.sh

# Courier MTA - deliver all mail to a smart host
apt-get install -y courier-mta courier-mta-ssl
e /etc/courier/defaultdomain
e /etc/courier/dsnfrom
e /etc/courier/aliases/system
e /etc/courier/esmtproutes
# : <SMART-HOST>,587 /SECURITY=REQUIRED
e /etc/courier/esmtpauthclient
# <SMART-HOST>,587 <user> <pass>

# set up certificates
# see: security/new-ssl-cert.sh
# test TLS connections: security/README.md

# clean up
apt-get autoremove --purge

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
