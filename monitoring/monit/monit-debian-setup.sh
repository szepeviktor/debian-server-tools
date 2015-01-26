#!/bin/bash
#
# Configure monit plugins
# These MONIT_* variables need to be filled in.
#
# DOCUMENTATION  :http://mmonit.com/wiki/Monit/ConfigurationExamples
# VERSION        :0.2

MONIT_BOOT_DELAY="120"
# hostname in alert address: root@
MONIT_EMAIL_HOST=""
# for system monitoring file name
MONIT_FULL_HOSTNAME=""
MONIT_SSH_PORT=""
MONIT_PHPFPM_SOCKET=""

Monit_enable() {
    local PLUGIN="$1"

    if ! [ -f "/etc/monit/monitrc.d/${PLUGIN}" ]; then
        echo "Plugin not found: (${PLUGIN})" >&2
        return 1
    fi

    ln -svf "/etc/monit/monitrc.d/${PLUGIN}" "/etc/monit/conf.d/${PLUGIN}" \
        || echo "Cannot create symlink" >&2
}

# INSTALL
#
# https://mmonit.com/monit/documentation/monit.html
#apt-get install -t wheezy-backports -y monit
# backported from sid: https://packages.debian.org/sid/amd64/monit/download
#wget http://mirror.szepe.net/debian/pool/main/m/monit/monit_5.10-1_amd64.deb
#dpkg -i monit_*_amd64.deb
# - configuration -
#service monit restart
# wait for start
#monit summary
#lynx 127.0.0.1:2812

[ -d /etc/monit/monitrc.d ] || exit 1
[ -z "$MONIT_BOOT_DELAY" ] && exit 2
[ -z "$MONIT_EMAIL_HOST" ] && exit 2
[ -z "$MONIT_FULL_HOSTNAME" ] && exit 2
[ -z "$MONIT_SSH_PORT" ] && exit 2
[ -z "$MONIT_PHPFPM_SOCKET" ] && exit 2

# filename only
MONIT_PHPFPM_SOCKET="$(basename "$MONIT_PHPFPM_SOCKET")"

## main configuration file
cat > "/etc/monit/monitrc.d/00_monitrc" <<MONITMAIN
# https://wiki.debian.org/monit
# https://mmonit.com/monit/documentation/monit.html

set daemon ${MONIT_BOOT_DELAY}
    with start delay ${MONIT_BOOT_DELAY}

# alert emails
set mailserver localhost port 25
set mail-format { from: root@${MONIT_EMAIL_HOST} }
set alert root@${MONIT_EMAIL_HOST}

# web interface
set httpd port 2812 and
    use address localhost
    allow localhost
MONITMAIN
#########

## system
cat > "/etc/monit/monitrc.d/01_${MONIT_FULL_HOSTNAME}" <<MONITSYSTEM
check system ${MONIT_FULL_HOSTNAME//[^0-9A-Za-z]/_}
    if loadavg (1min) > 4 then alert
    if loadavg (5min) > 2 then alert
    if memory usage > 75% then alert
    if swap usage > 25% then alert
    if cpu usage (user) > 70% then alert
    if cpu usage (system) > 30% then alert
    if cpu usage (wait) > 20% then alert
MONITSYSTEM
###########

## sshd
sed -i "s/port 22 with proto ssh/port ${MONIT_SSH_PORT} with proto ssh/" /etc/monit/monitrc.d/openssh-server

## rsyslog
#FIXME --MARK--
sed -i 's|check file rsyslog_file with path /var/log/messages|check file rsyslog_file with path /var/log/syslog|' /etc/monit/monitrc.d/rsyslog

## unscd
cat > "/etc/monit/monitrc.d/unscd" <<MONITUNSCD
# µNameservice caching daemon (unscd)
check process nscd with pidfile /var/run/nscd/nscd.pid
    group system
    start program = "/etc/init.d/unscd start"
    stop  program = "/etc/init.d/unscd stop"
    if 5 restarts within 5 cycles then timeout
    depends on nscd_bin
    depends on nscd_rc

check file nscd_bin with path /usr/sbin/nscd
    group system
    if failed permission 755 then unmonitor
    if failed uid root then unmonitor
    if failed gid root then unmonitor

check file nscd_rc with path /etc/init.d/unscd
    group system
    if failed permission 755 then unmonitor
    if failed uid root then unmonitor
    if failed gid root then unmonitor
MONITUNSCD
##########

## fail2ban
cat > "/etc/monit/monitrc.d/fail2ban" <<MONITFAIL2BAN
check process fail2ban with pidfile /var/run/fail2ban/fail2ban.pid
    group services
    start program = "/etc/init.d/fail2ban force-start"
    stop  program = "/etc/init.d/fail2ban stop || :"
    if failed unixsocket /var/run/fail2ban/fail2ban.sock then restart
    if 5 restarts within 5 cycles then timeout

check file fail2ban_log with path /var/log/fail2ban.log
    if match "ERROR|WARNING" then alert
MONITFAIL2BAN
#############


## enable custom plugins
Monit_enable 00_monitrc
Monit_enable "01_${MONIT_FULL_HOSTNAME}"
Monit_enable unscd
Monit_enable fail2ban

## enable contributed plugins
# https://github.com/perusio/monit-miscellaneous
wget -O /etc/monit/monitrc.d/php-fpm-unix \
    "https://raw.githubusercontent.com/szepeviktor/monit-miscellaneous/patch-1/php-fpm-unix"
#has a bug    "https://raw.githubusercontent.com/perusio/monit-miscellaneous/master/php-fpm-unix"
sed -i "s|unixsocket /var/run/php-fpm.sock then|unixsocket /var/run/${MONIT_PHPFPM_SOCKET} then|" \
    /etc/monit/monitrc.d/php-fpm-unix
sed -i "s|alert root@localhost only on {timeout}$|alert root@${MONIT_EMAIL_HOST} only on {timeout}|g" \
    /etc/monit/monitrc.d/php-fpm-unix
sed -i "s|alert root@localhost$||g" \
    /etc/monit/monitrc.d/php-fpm-unix
Monit_enable php-fpm-unix

# http://storage.fladi.at/~FladischerMichael/monit/
# mirror: https://github.com/szepeviktor/FladischerMichael.monit
if [ -x /usr/sbin/courieresmtpd ]; then
    wget -O /etc/monit/monitrc.d/courier \
        "https://raw.githubusercontent.com/szepeviktor/FladischerMichael.monit/master/courier.test"
    Monit_enable courier
fi

if [ -x /usr/lib/courier/courier-authlib/authdaemond ]; then
    wget -O /etc/monit/monitrc.d/courier-auth \
        "https://github.com/szepeviktor/FladischerMichael.monit/raw/master/courier-auth.test"
    Monit_enable courier-auth
fi

if [ -x /usr/bin/imapd ]; then
    wget -O /etc/monit/monitrc.d/courier-imap \
        "https://github.com/szepeviktor/FladischerMichael.monit/raw/master/courier-imap.test"
    Monit_enable courier-imap
fi
# more: https://extremeshok.com/5207/monit-configs-for-ubuntu-debian-centos-rhce-redhat/

## enable built-in plugins
Monit_enable apache2
Monit_enable cron
Monit_enable mysql
Monit_enable openssh-server
Monit_enable rsyslog

## enable built-in plugins - hardware related
#Monit_enable acpid
#Monit_enable smartmontools
#Monit_enable mdadm

## enable built-in plugins - others
#Monit_enable at
#Monit_enable memcached
#Monit_enable nginx
#Monit_enable openntpd
#Monit_enable pdns-recursor
#Monit_enable postfix
#Monit_enable snmpd

## mail
#Monit_enable spamassassin
#Monit_enable courier-imap
