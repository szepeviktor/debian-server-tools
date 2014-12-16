#!/bin/bash
#
# Debian server setup - wheezy amd64
# Not a script but a manual.
#
# OVH VPS data: /etc/ovhrc

# How to choose VPS provider?
# disk access time
# CPU speed
# worldwide/local bandwidth
# nightime technical support: network or hardware failure response time
# daytime technical and billing support
# DoS mitigation


exit 0

# download this repo
git clone https://github.com/szepeviktor/debian-server-tools.git
cd debian-server-tools/ && git submodule init && git submodule update


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
deb <MIRROR> wheezy main contrib non-free
# security
deb http://security.debian.org/ wheezy/updates main contrib non-free
# updates (previously known as 'volatile')
deb <MIRROR> wheezy-updates main
# backports
# http://backports.debian.org/changes/wheezy-backports.html
deb <MIRROR> wheezy-backports main

# disable apt languages
echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/00languages

# upgrade
apt-get update
apt-get dist-upgrade -y
apt-get install -y ssh sudo ca-certificates most lftp bash-completion htop bind9-host mc lynx ncurses-term

# input
echo "alias e='mcedit'" > /etc/profile.d/editor.sh || echo "ERROR: alias 'e'"
sed -i 's/^# \(".*: history-search-.*ward\)$/\1/' /etc/inputrc || echo "ERROR: history-search-backward"
sed -e 's/\(#.*enable bash completion\)/#\1/' -e '/#.*enable bash completion/,+8 { s/^#// }' -i /etc/bash.bashrc || echo "ERROR: bash completion"
echo -e "\ncontent_disposition = on" >> /etc/wgetrc
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
export GREP_OPTIONS="--color"
alias iftop='NCURSES_NO_UTF8_ACS=1 iftop -nP'
alias grep='grep $GREP_OPTIONS'
# putty / Connection / Data / Terminal-type string: putty-256color
export MC_SKIN="modarin256root-defbg"

# user
U="viktor"
adduser $U
# enter password...
K="<PUBLIC-KEY>"
S="/home/$U/.ssh"; mkdir --mode 700 "$S"; echo "$K" >> "${S}/authorized_keys2"; chown -R $U:$U "$S"
adduser $U sudo

# remove root password
nano /etc/shadow
# sshd on another port
sed 's/^Port 22$/#Port 22\nPort 3022/' -i /etc/ssh/sshd_config
# add IP blocking
# see: security/README.md
nano /etc/hosts.deny
service ssh restart
netstat -antup|grep sshd

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
e /etc/sysctl.conf

# misc. files
e /etc/rc.local
e /etc/profile
e /etc/motd

# network
e /etc/network/interfaces
# iface eth0 inet static
#     address <IP>
#     gateway <GW>
ifconfig -a
route -n -4
route -n -6
netstat -antup
e /etc/resolv.conf
#nameserver 8.8.8.8
#nameserver 8.8.4.4
#nameserver <LOCAL_NS>
#options timeout:2
##options rotate
ping6 -c 4 ipv6.google.com
# should be A 93.184.216.119
host -v -t A example.com
# view network graph: http://bgp.he.net/ip/<IP>

# hostname
# set A record and PTR record
# consider: http://www.iata.org/publications/Pages/code-search.aspx
#           http://www.world-airport-codes.com/
H="<HOST-NAME>"
# search for the old hostname
grep -ir "$(hostname)" /etc/
hostname "$H"
echo "$H" > /etc/hostname
echo "$H" > /etc/mailname
# add:
# # <ORIG-REVERSE-DNS>
e /etc/hosts

# locale, timezone
locale
locale -a
dpkg-reconfigure locales
cat /etc/timezone
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
dpkg -l|egrep "~squeeze|python2\.6"
# non-Debian packages
aptitude search '?narrow(?installed, !?origin(Debian))'
# obsolete pacakages
aptitude search '?obsolete'
# vps monitoring
ps aux|grep -v "grep"|egrep "snmp|vmtools|xe-daemon"
# see: package/vmware-tools-wheezy.sh
dpkg -l|egrep "fancontrol|acpid|laptop-detect|eject|lm-sensors|sensord|smartmontools|mdadm|lvm|usbutils"
dpkg -l|most
apt-get autoremove --purge

# essential packages
apt-get install -y heirloom-mailx unattended-upgrades apt-listchanges cruft debsums \
    bootlogd ntpdate gcc make colordiff pwgen dos2unix strace ccze
apt-get install -t wheezy-backports -y rsyslog whois git
cd /root/; git clone https://github.com/szepeviktor/debian-server-tools.git
cd debian-server-tools/ && git submodule init && git submodule update

# IRQ balance
declare -i CPU_COUNT="$(grep -c "^processor" /proc/cpuinfo)"
[ "$CPU_COUNT" -gt 1 ] && apt-get install -y irqbalance && cat /proc/interrupts

# time
cp -v monitoring/ntpdated /usr/local/sbin/
./install-cron.sh monitoring/ntpdated
# set nearest time server: http://www.pool.ntp.org/en/
# NTPSERVERS="0.uk.pool.ntp.org 1.uk.pool.ntp.org 2.uk.pool.ntp.org 3.uk.pool.ntp.org"
# NTPSERVERS="0.de.pool.ntp.org 1.de.pool.ntp.org 2.de.pool.ntp.org 3.de.pool.ntp.org"
# NTPSERVERS="0.hu.pool.ntp.org 1.hu.pool.ntp.org 2.hu.pool.ntp.org 3.hu.pool.ntp.org"
e /etc/default/ntpdate
# OVH
# NTPSERVERS="ntp.ovh.net"

#TODO  measure CPU speed bz2 25MB, disk access time and throughput hdd-, network speed multiple connections
# https://github.com/mgutz/vpsbench/blob/master/vpsbench

# backported unscd
wget -O unscd_amd64.deb http://szepeviktor.github.io/debian/pool/main/u/unscd/unscd_0.51-1~bpo70+1_amd64.deb
dpkg -i unscd_amd64.deb
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
make && ./slabbed-or-not|tee ../slabbed-or-not.log && cd ..

# VPS check
#FIXME install.sh ...
cp -v monitoring/vpscheck.sh /usr/local/sbin/
vpscheck.sh -gen
./install-cron.sh /usr/local/sbin/vpscheck.sh

# fail2ban latest version's .dsc: https://tracker.debian.org/pkg/fail2ban
apt-get install -y geoip-bin recode python3-pyinotify
apt-get install -t wheezy-backports -y init-system-helpers
# latest geoip-database-contrib version
GEOIP=$(wget -qO- https://packages.debian.org/sid/all/geoip-database-contrib/download|grep -o '[^"]\+ftp.fr.debian.org/debian[^"]\+\.deb')
wget -O geoip-database-contrib_all.deb "$GEOIP"
dpkg -i geoip-database-contrib_all.deb
# .dsc from sid: https://packages.debian.org/sid/fail2ban
#dget -ux <DSC-URL>
#dpkg-checkbuilddeps && dpkg-buildpackage -b -us -uc
# packaged 0.9.1
wget -O fail2ban_all.deb http://szepeviktor.github.io/debian/pool/main/f/fail2ban/fail2ban_0.9.1-1_all.deb
dpkg -i fail2ban_all.deb
# filter: apache-combined, apache-asap
# action: sendmail-geoip-lines.local
e /etc/fail2ban/jail.local
e /etc/fail2ban/fail2ban.local

# apt repositories for these softwares, see package/README.md
e /etc/apt/sources.list.d/others.list
eval "$(grep "^#K:" /etc/apt/sources.list.d/others.list | cut -d' ' -f 2-)"
apt-get update

# Apache 2.4.x (jessie backport)
apt-get install -y -t wheezy-experimental apache2-mpm-itk apache2-utils libapache2-mod-fastcgi
a2enmod actions
a2enmod rewrite
a2enmod headers
a2enmod deflate
a2enmod expires
a2enconf php-fpm
a2enconf h5bp
e /etc/apache2/conf-enabled/security.conf
# ServerTokens Prod

# for poorly written themes/plugins
apt-get install -y mod-pagespeed-stable
# comment out mod-pagespeed/deb
e /etc/apt/sources.list.d/others.list

# PHP 5.5 from DotDeb
apt-get install -y php-pear php5-apcu php5-cgi php5-cli php5-curl php5-dev php5-fpm php5-gd \
    php5-mcrypt php5-mysqlnd php5-readline php5-sqlite
# ??? pkg-php-tools
PHP_TZ="$(head -n 1 /etc/timezone)"
sed -i 's/^expose_php = .*$/expose_php = Off/' /etc/php5/fpm/php.ini
sed -i 's/^max_execution_time = .*$/max_execution_time = 65/' /etc/php5/fpm/php.ini
sed -i 's/^memory_limit = .*$/memory_limit = 384M/' /etc/php5/fpm/php.ini
sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 20M/' /etc/php5/fpm/php.ini
sed -i 's/^allow_url_fopen = .*$/allow_url_fopen = Off/' /etc/php5/fpm/php.ini
sed -i 's|^date.timezone = .*$|date.timezone = ${PHP_TZ}|' /etc/php5/fpm/php.ini
grep -v "^#\|^;\|^$" /etc/php5/fpm/php.ini|most

# suhosin: https://github.com/stefanesser/suhosin/releases
# version 0.9.37
SUHOSIN_URL="<RELEASE-TAR-GZ>"
SUHOSIN_URL="https://github.com/stefanesser/suhosin/archive/suhosin-0.9.37.tar.gz"
wget -qO- "$SUHOSIN_URL"|tar xz && cd suhosin-suhosin-*
phpize && ./configure && make && make test || echo "ERROR: suhosin build failed."
make install && cp -v suhosin.ini /etc/php5/fpm/conf.d/00-suhosin.ini && cd ..
# enable
sed -i 's/^;\(extension=suhosin.so\)$/\1/' /etc/php5/fpm/conf.d/00-suhosin.ini || echo "ERROR: enabling suhosin"

# MariaDB
apt-get install -y mariadb-server-10.0 mariadb-client-10.0
echo -e "[mysql]\nuser=root\npass=<PASSWORD>\ndefault-character-set=utf8" >> /root/.my.cnf && chmod 600 /root/.my.cnf

# control panel for opcache and APC
TOOLS_DOCUMENT_ROOT="<TOOLS-DOCUMENT-ROOT>"
TOOLS_DOCUMENT_ROOT=/home/web/public_html/server/
cp -v webserver/ocp.php "$TOOLS_DOCUMENT_ROOT"
wget -P "$TOOLS_DOCUMENT_ROOT" https://www.debian.org/favicon.ico
echo -e "User-agent: *\nDisallow: /" > "${TOOLS_DOCUMENT_ROOT}/robots.txt"
# apc/tar
#APC_URL="http://pecl.php.net/get/APC-3.1.13.tgz"
#wget -qO- "$APC_URL" | tar xz --no-anchored apc.php && mv APC*/apc.php "$TOOLS_DOCUMENT_ROOT" && rmdir APC*
# apc trunk for PHP 5.4-
php -r 'if(1!==version_compare("5.5",phpversion())) exit(1);' \
    && wget -O "${TOOLS_DOCUMENT_ROOT}/apc.php" "http://git.php.net/?p=pecl/caching/apc.git;a=blob_plain;f=apc.php;hb=HEAD"
# APCu master for PHP 5.5+
php -r 'if(1===version_compare("5.5",phpversion())) exit(1);' \
    && wget -O "${TOOLS_DOCUMENT_ROOT}/apc.php" "https://github.com/krakjoe/apcu/raw/simplify/apc.php"

# PHPMyAdmin see: package/phpmyadmin-get-sf.sh
cd <PHPMYADMIN_DIR>
cp config.sample.inc.php config.inc.php
pwgen -y 30 1
# http://docs.phpmyadmin.net/en/latest/config.html#basic-settings
e config.inc.php
# $cfg['blowfish_secret'] = '<RANDOM-STRING>';
# $cfg['DefaultLang'] = 'en';
# $cfg['PmaNoRelation_DisableWarning'] = true;
# $cfg['SuhosinDisableWarning'] = true;

# wp-cli
WPCLI_URL="https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
wget -O /usr/local/bin/wp "$WPCLI_URL" && chmod +x /usr/local/bin/wp
WPCLI_COMPLETION_URL="https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash"
wget -O- "$WPCLI_COMPLETION_URL"|sed 's/wp cli completions/wp --allow-root cli completions/' > /etc/bash_completion.d/wp-cli
# if you have suhosin in global php5 config
#grep "[^;#]*suhosin\.executor\.include\.whitelist.*phar" /etc/php5/cli/conf.d/*suhosin*.ini || echo "Please enable phar in suhosin!"

# drush - https://github.com/drush-ops/drush/releases
wget -qO "getcomposer.php" https://getcomposer.org/installer
php "getcomposer.php" --install-dir=/usr/local/bin --filename=composer
mkdir -p /opt/drush && cd /opt/drush
composer require drush/drush:6.*
ln -sv /opt/drush/vendor/bin/drush /usr/local/bin/drush
# set up Drupal site
#sudo -u <SITE-USER> -i -- drush dl drupal --drupal-project-rename=<SITE_DIR>
#sudo -u <SITE-USER> -i -- cd <SITE_DIR>
#sudo -u <SITE-USER> -i -- drush site-install standard \
#    --db-url='mysql://[db_user]:[db_pass]@localhost/[db_name]' --site-name=<SITE_NAME> \
#    --account-name=<USERNAME> --account-pass=<USERPASS>
#sudo -u <SITE-USER> -i -- drush --root=<DOCUMENT_ROOT> vset --yes file_private_path "<PRIVATE-PATH>"
#sudo -u <SITE-USER> -i -- drush --root=<DOCUMENT_ROOT> vset --yes file_temporary_path "<TEMP_DIRECTORY>"
#sudo -u <SITE-USER> -i -- drush --root=<DOCUMENT_ROOT> vset --yes cron_safe_threshold 0

# Courier MTA - deliver all mail to a smart host
apt-get install -y courier-mta courier-ssl
# SMTPS: apt-get install -y courier-mta courier-mta-ssl
dpkg -l|egrep "postfix|exim"
apt-get purge exim4 exim4-base exim4-config exim4-daemon-light
# hostname
e /etc/courier/me
# default domain
e /etc/courier/defaultdomain
e /etc/courier/dsnfrom
e /etc/courier/aliases/system
e /etc/courier/esmtproutes
# : <SMART-HOST>,587 /SECURITY=REQUIRED
# SMTP listen only on localhost?
e /etc/courier/esmtpd
e /etc/courier/esmtpd-ssl
# ADDRESS=127.0.0.1
makealiases
makesmtpaccess
service courier-mta restart
service courier-mta-ssl restart
echo "This is a test mail." | mailx -s "[first] subject of the first email" <ADDRESS>
# on the smarthost add:
# <IP><TAB>allow,RELAYCLIENT,AUTH_REQUIRED=0

# latest Spamassassin version
#SA_URL=$(wget -qO- https://packages.debian.org/sid/all/spamassassin/download|grep -o '[^"]\+ftp.fr.debian.org/debian[^"]\+\.deb')
#wget -O spamassassin_all.deb "$SA_URL"
#dpkg -i spamassassin_all.deb

# adding a website see: webserver/Add-site.md

# SSL for web/mail/etc.
# set up certificates
# see: security/new-ssl-cert.sh
# test TLS connections: security/README.md

# monit-oring
# https://mmonit.com/monit/documentation/monit.html
#apt-get install -t wheezy-backports -y monit
# backported from sid: https://packages.debian.org/sid/amd64/monit/download
wget -O monit_amd64.deb http://szepeviktor.github.io/debian/pool/main/m/monit/monit_5.10-1_amd64.deb
dpkg -i monit_amd64.deb
# for configuration see: monitoring/monit
service monit restart
# wait for start
tail -f /var/log/monit.log
monit summary
lynx 127.0.0.1:2812

# munin - network-wide graphing
apt-get install -y time liblwp-useragent-determined-perl libcache-cache-perl
apt-get install -t wheezy-backports -y munin-node
# for configuration see: monitoring/munin
# enable plugins by hand
munin-node-configure --shell
# review plugins
ps aux
ls -l /etc/munin/plugins
# check plugins
ls /etc/munin/plugins/|while read P;do if ! munin-run "$P" config;then echo "ERROR ${P} config status=$?";sleep 4;
    elif ! munin-run "$P";then echo "ERROR ${P} fetch status=$?";sleep 4;fi;done
# allow munin server IP in node config
# regexp IP address: ^1\.2\.3\.4$
e /etc/munin/munin-node.conf
service munin-node restart

# clean up
apt-get autoremove --purge

# backup /etc
tar cJf "/root/etc-backup_$(date +%Y%m%d).tar.xz" /etc/

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
