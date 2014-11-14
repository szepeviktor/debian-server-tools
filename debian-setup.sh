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
e /etc/sysctl.conf

# network
netstat -antup
ifconfig
route -n -4
route -n -6
ping6 -n 4 ipv6.google.com
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
# saearch for the old hostname
grep -ir "$(hostname)" /etc/
hostname "$H"
echo "$H" > /etc/hostname
echo "$H" > /etc/mailname
e /etc/hosts

# locale, timezone
locale
locale -a
cat /etc/timezone
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
dpkg -l|grep "~squeeze"
# vps monitoring
ps aux|grep -v "grep"|egrep "snmp|vmtools|xe-daemon"
# see: package/vmware-tools-wheezy.sh
dpkg -l|egrep "fancontrol|acpid|laptop-detect|eject|lm-sensors|sensord|smartmontools|mdadm|lvm|usbutils"
dpkg -l|most
apt-get autoremove --purge

# essential packages
apt-get install -y heirloom-mailx unattended-upgrades apt-listchanges cruft debsums \
    bootlogd ntpdate gcc make colordiff pwgen dos2unix strace
apt-get install -t wheezy-backports -y rsyslog whois git
cd /root/; git clone https://github.com/szepeviktor/debian-server-tools.git

# IRQ balance
declare -i CPU_COUNT="$(grep -c "^processor" /proc/cpuinfo)"
[ "$CPU_COUNT" -gt 1 ] && apt-get install -y irqbalance && cat /proc/interrupts

# time
./install-cron.sh monitoring/ntpdated
# set nearest time server: http://www.pool.ntp.org/en/
e /etc/default/ntpdate
# OVH: ntp.ovh.net

#TODO  measure CPU speed bz2 25MB, disk access time and throughput hdd-, network speed multiple connections
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
e /etc/fail2ban/fail2ban.local

# apt repositories for these softwares
# see package/README.md
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
# chmod 750 public_html/server

# for poorly written themes/plugins
apt-get install -y mod-pagespeed-stable

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

# suhosin: https://github.com/stefanesser/suhosin/releases
SUHOSIN_URL="<RELEASE-TAR-GZ>"
wget -qO- "$SUHOSIN_URL"|tar xz && cd suhosin-suhosin-*
phpize && ./configure && make && make test || echo "ERROR: suhosin build failed."
make install && cp -v suhosin.ini /etc/php5/fpm/conf.d/00-suhosin.ini && cd ..
# enable
sed -i 's/^;\(extension=suhosin.so\)$/\1/' /etc/php5/fpm/conf.d/00-suhosin.ini || echo "ERROR: enabling suhosin"

# MariaDB
apt-get install -y mariadb-server-10.0 mariadb-client-10.0
echo -e "[mysql]\nuser=root\npass=<PASSWORD>" >> /root/.my.cnf && chmod 600 /root/.my.cnf

# control panel for opcache and APC
TOOLS_DOCUMENT_ROOT="<TOOLS-DOCUMENT-ROOT>"
cp -v webserver/ocp.php "$TOOLS_DOCUMENT_ROOT"
wget -P "$TOOLS_DOCUMENT_ROOT" https://www.debian.org/favicon.ico
echo -e "User-agent: *\nDisallow: /" > "${TOOLS_DOCUMENT_ROOT}/robots.txt"
#APC_URL="http://pecl.php.net/get/APC-3.1.13.tgz"
#wget -qO- "$APC_URL" | tar xz --no-anchored apc.php && mv APC*/apc.php "$TOOLS_DOCUMENT_ROOT" && rmdir APC*
wget -O "${TOOLS_DOCUMENT_ROOT}/apc.php" "http://git.php.net/?p=pecl/caching/apc.git;a=blob_plain;f=apc.php;hb=HEAD"

# PHPMyAdmin see: package/phpmyadmin-get.sh
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
#grep "[^;#]*suhosin\.executor\.include\.whitelist.*phar" /etc/php5/cli/conf.d/suhosin*.ini || echo "Please enable phar in suhosin!"

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
apt-get install -y courier-mta courier-mta-ssl
e /etc/courier/me
e /etc/courier/dsnfrom
e /etc/courier/aliases/system
e /etc/courier/esmtproutes
# : <SMART-HOST>,587 /SECURITY=REQUIRED
e /etc/courier/esmtpauthclient
# <SMART-HOST>,587 <user> <pass>

# Apache add new site
adduser --disabled-password <USER>
# add permissions for real users
cd /etc/sudoers.d/
cd /home/<USER>/public_html/
mkdir {session,tmp,server,pagespeed,backup}
htpasswd -c ./htpasswords <LOGIN>
cd /etc/php5/fpm/pool.d
cd /etc/apache2/sites-available
a2ensite <SITE>
service php5-fpm restart && service apache2 restart
# web application' cron
cd /etc/cron.d
# create WordPress database fromwp-config, see mysql/wp-createdb.sh

# set up certificates
# see: security/new-ssl-cert.sh
# test TLS connections: security/README.md

# monit-oring
# https://mmonit.com/monit/documentation/monit.html
#apt-get install -t wheezy-backports -y monit
# from sid: https://packages.debian.org/sid/amd64/monit/download
#wget http://mirror.szepe.net/debian/pool/main/m/monit/monit_5.10-1_amd64.deb
dpkg -i monit_*_amd64.deb
e /etc/monit/monitrc.d/00_monitrc
# # https://wiki.debian.org/monit
# # https://mmonit.com/monit/documentation/monit.html
#
# set daemon 120
#     with start delay 120
#
# # alert emails
# set mailserver localhost port 25
# set mail-format { from: <root@H> }
# set alert root@<H>
#
# # web interface
# set httpd port 2812 and
#     use address localhost
#     allow localhost
e "/etc/monit/monitrc.d/${H}"
# check system ${H//[^a-z0-9]/_}
#     if loadavg (1min) > 4 then alert
#     if loadavg (5min) > 2 then alert
#     if memory usage > 75% then alert
#     if swap usage > 25% then alert
#     if cpu usage (user) > 70% then alert
#     if cpu usage (system) > 30% then alert
#     if cpu usage (wait) > 20% then alert
e /etc/monit/monitrc.d/unscd
# # µNameservice caching daemon (unscd)
#
#  check process nscd with pidfile /var/run/nscd/nscd.pid
#    group system
#    start program = "/etc/init.d/unscd start"
#    stop  program = "/etc/init.d/unscd stop"
#    if 5 restarts within 5 cycles then timeout
#    depends on nscd_bin
#    depends on nscd_rc
#
#  check file nscd_bin with path /usr/sbin/nscd
#    group system
#    if failed permission 755 then unmonitor
#    if failed uid root then unmonitor
#    if failed gid root then unmonitor
#
#  check file nscd_rc with path /etc/init.d/unscd
#    group system
#    if failed permission 755 then unmonitor
#    if failed uid root then unmonitor
#    if failed gid root then unmonitor
# edit SSH port
wget -O /usr/local/share/munin/plugins/monit_parser https://github.com/munin-monitoring/contrib/raw/master/plugins/monit/monit_parser
ln -sv /usr/local/share/munin/plugins/monit_parser /usr/share/munin/plugins/monit_parser
# [monit_parser]
# user root
e /etc/monit/monitrc.d/openssh-server
cd /etc/monit/conf.d
ln -sv ../monitrc.d/00_monitrc 00_monitrc
ln -sv "../monitrc.d/${H}" "$H"
ln -sv ../monitrc.d/unscd unscd

ln -sv ../monitrc.d/courier courier
ln -sv ../monitrc.d/courier-auth courier-auth
ln -sv ../monitrc.d/fail2ban fail2ban
#e socket path
ln -sv ../monitrc.d/php-fpm-unix php-fpm-unix

ln -sv ../monitrc.d/apache2 apache2
ln -sv ../monitrc.d/cron cron
ln -sv ../monitrc.d/mysql mysql
ln -sv ../monitrc.d/openssh-server openssh-server
ln -sv ../monitrc.d/rsyslog rsyslog
service monit restart
lynx 127.0.0.1:2812
# https://github.com/perusio/monit-miscellaneous
# http://storage.fladi.at/~FladischerMichael/monit/
#TODO list services from above, auto-enable.sh, move to monitoring/monit

# munin - network-wide graphing
apt-get install -t wheezy-backports -y munin-node
apt-get install -y time liblwp-useragent-determined-perl libcache-cache-perl
# latest mysql plugin
MUNIN_MYSQL_URL="https://github.com/munin-monitoring/munin/raw/devel/plugins/node.d/mysql_.in"
mkdir -p /usr/local/share/munin/plugins
wget -qO- "$MUNIN_MYSQL_URL"|sed 's|^#!@@PERL@@$|#!/usr/bin/env perl|' > /usr/local/share/munin/plugins/mysql_
chmod 755 /usr/local/share/munin/plugins/mysql_
ln -svf /usr/local/share/munin/plugins/mysql_ /usr/share/munin/plugins/mysql_
munin-node-configure --suggest
munin-node-configure --shell
# allow munin server IP
e /etc/munin/munin-node.conf
e /etc/munin/plugin-conf.d/munin-node
# [fail2ban]
# user root
# [http_loadtime]
# env.target http://website.tld/
e /usr/share/munin/plugins/mysql_
# mysql_qcache/Qcache_queries_in_cache
# , cdef => 'Qcache_queries_in_cache,1024,/', type => 'GAUGE'
e /usr/share/munin/plugins/courier_mta_mailqueue
e /usr/share/munin/plugins/courier_mta_mailstats
e /usr/share/munin/plugins/courier_mta_mailvolume
# courier_mta*/"graph_category
# graph_category mail
# print "graph_category mail\n";
# review plugins
ls -l /etc/munin/plugins
service munin-node restart
# add node to munin master
# >>> https://github.com/stars?q=munin
# https://github.com/tjstein/php5-fpm-munin-plugins
#TODO list services from above
#TODO https://www.monitis.com/monitoring-plan-builder

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
