# Basic packages
apt-get install -y \
    ipset time netcat-openbsd lftp \
    ncurses-term bash-completion mc htop most less
    localepurge unattended-upgrades apt-listchanges cruft debsums etckeeper \
    gcc libc6-dev make strace \
    moreutils logtail whois unzip heirloom-mailx apg dos2unix ccze git colordiff mtr-tiny ntpdate
# Backports
apt-get install -t jessie-backports -y needrestart
# From custom repos
apt-get install -y goaccess ipset-persistent

debian-setup/most
debian-setup/mc

# debian-server-tools
cd /usr/local/src/
git clone --recursive https://github.com/szepeviktor/debian-server-tools.git
export D="$(pwd)/debian-server-tools"

# All tools
( cd ${D}; ls tools/ | xargs -I "%" ./install.sh tools/% )

# Create directory for non-distribution files
mkdir /root/dist-mod
cd /root/dist-mod/

# Alert on boot and on halt
cp -v ${D}/monitoring/boot-alert /etc/init.d/
update-rc.d boot-alert defaults
cp -v ${D}/monitoring/halt-alert /etc/init.d/
update-rc.d halt-alert defaults

# Custom APT repository script
( cd ${D}; ./install.sh package/apt-add-repo.sh )

# Block dangerous networks
( cd ${D}/security/myattackers-ipsets/; ./ipset-install.sh )
( cd ${D}; ./install.sh security/myattackers.sh )
# Initialize iptables chain
myattackers.sh -i

# rsyslogd immark plugin
#     http://www.rsyslog.com/doc/rsconf1_markmessageperiod.html
editor /etc/rsyslog.conf
#     $ModLoad immark
#     $MarkMessagePeriod 1800
#
#     # Alert root
#     *.warn  :omusrmsg:root,viktor
service rsyslog restart

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
service cron restart

# Time synchronization
# Virtual servers only
editor /etc/default/hwclock
#    HWCLOCKACCESS=no
# Check clock source
cat /sys/devices/system/clocksource/clocksource0/available_clocksource
# KVM (???no ntp)
# https://s19n.net/articles/2011/kvm_clock.html
dmesg | grep "kvm-clock"
grep "kvm-clock" /sys/devices/system/clocksource/clocksource0/current_clocksource
# Without monit
( cd ${D}; ./install.sh monitoring/monit/services/ntpdate_script )
echo -e '#!/bin/bash\n/usr/local/bin/ntp-alert.sh' > /etc/cron.daily/ntp-alert
chmod +x /etc/cron.daily/ntp-alert

# 1) VMware
vmware-toolbox-cmd timesync enable
vmware-toolbox-cmd timesync status
# 2) Chrony
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
# 3) Systemd
timedatectl set-ntp 1

# µnscd
apt-get install -t jessie-backports -y unscd
editor /etc/nscd.conf
#     enable-cache            hosts   yes
#     positive-time-to-live   hosts   60
#     negative-time-to-live   hosts   20
service unscd --full-restart

# msmtp (has no queue!)
apt-get install -y msmtp-mta
# /usr/share/doc/msmtp/examples/msmtprc-system.example
cp -vf ${D}/mail/msmtprc /etc/
# Configure Mandrill
#     https://www.mandrill.com/signup/
#     http://msmtp.sourceforge.net/doc/msmtp.html
echo "This is a test mail."|mailx -s "[first] Subject of the first email" ADDRESS

# Courier MTA - deliver all messages to a smarthost
# See /mail/courier-mta-satellite-system.sh

# Apache 2.4 with mpm-events
apt-get install -y apache2 apache2-utils
# Consider libapache2-mod-qos (testing backport)
adduser --disabled-password --gecos "" web
editor /etc/apache2/envvars
#     export APACHE_RUN_USER=web
#     export APACHE_RUN_GROUP=web
a2enmod actions rewrite headers deflate expires proxy_fcgi
# Comment out '<Location /server-status>' block
editor /etc/apache2/mods-available/status.conf
a2enmod ssl
yes|cp -vf ${D}/webserver/apache-conf-available/*.conf /etc/apache2/conf-available/
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
sed -i 's/^post_max_size\s*=.*$/post_max_size = 4M/' /etc/php5/fpm/php.ini
sed -i 's/^upload_max_filesize\s*=.*$/upload_max_filesize = 4M/' /etc/php5/fpm/php.ini # FullHD JPEG
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

grep -Ev "^\s*#|^\s*;|^\s*$" /etc/php5/fpm/php.ini | pager
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

# @TODO .ini-handler, Search for it!

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
sed -i 's/^post_max_size\s*=.*$/post_max_size = 4M/' /etc/php/7.0/fpm/php.ini
# FullHD random image:  rawtoppm < /dev/urandom 1920 1080 > random-fullhd.ppm
sed -i 's/^upload_max_filesize\s*=.*$/upload_max_filesize = 4M/' /etc/php/7.0/fpm/php.ini # FullHD JPEG
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
sed -i 's/^;opcache.max_accelerated_files\s*=.*$/opcache.max_accelerated_files = 10000/' /etc/php/7.0/fpm/php.ini
# APCu
echo -e "\n[apc]\napc.enabled = 1\napc.shm_size = 64M" >> /etc/php/7.0/fpm/php.ini

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
#ls -l /etc/php5/fpm/conf.d/70-suhosin.ini

# PHP file modification time protection
# https://ioncube24.com/signup

# @TODO .ini-handler, Search for it!

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
# See /webserver/add-prg-site.sh
# Add a production website
# See /webserver/add-site.sh

# In-memory object cache
apt-get install -y redis-server

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
rm -f composer-setup.php

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
# See /webserver/preload-cache.sh

# Spamassassin
apt-get install -y libmail-dkim-perl \
    libsocket6-perl libsys-hostname-long-perl libnet-dns-perl libnetaddr-ip-perl \
    libcrypt-openssl-rsa-perl libdigest-hmac-perl libio-socket-inet6-perl libnet-ip-perl \
    libcrypt-openssl-bignum-perl
( cd /root/dist-mod/; Getpkg spamassassin )

# SSL certificate for web, mail etc.
# See /security/new-ssl-cert.sh

# Test TLS connections
# See /security/README.md

# ProFTPD
# When the default locale for your system is not en_US.UTF-8
# be sure to add this to /etc/default/proftpd for fail2ban to understand dates.
#     export LC_TIME="en_US.UTF-8"

# Simple syslog monitoring
( cd ${D}; ./install.sh monitoring/syslog-errors.sh )

# Monit - monitoring
( cd ${D}/monitoring/monit/; install --mode=0640 -D -t /etc/monit monit.defaults; ./monit-debian-setup.sh )

# Munin - network-wide graphing
# See /monitoring/munin/munin-debian-setup.sh

# Aruba ExtraControl (serclient)
#     http://admin.dc3.arubacloud.hu/Manage/Serial/SerialManagement.aspx
wget -nv https://admin.dc3.arubacloud.hu/Installers/debian/aruba-serclient_0.01-1_all.deb
dpkg -i aruba-serclient_*_all.deb
# Set log level
# INFO 20, WARNING 30
echo -e "[LOG]\n#level = 20\nlevel = 30" >> /opt/serclient/serclient.ini
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
#npm install -g less less-plugin-clean-css

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
