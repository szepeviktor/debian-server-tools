#!/bin/bash
#
# Configure monit plugins
#
# VERSION       :0.4.1
# DATE          :2015-10-11
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install monit
# DOCS          :https://mmonit.com/wiki/Monit/ConfigurationExamples
# DOCS          :https://mmonit.com/monit/documentation/monit.html

# Usage
#
#     editor ./monit-debian-setup.sh
#     ./monit-debian-setup.sh
#     service monit restart
#     sleep 40 && monit summary
#     lynx 127.0.0.1:2812

# These variables need to be FILLED IN!
MONIT_BOOT_DELAY="40"
# Hostname in alert address: root@
MONIT_EMAIL_HOST=""
# Name for system monitoring file
MONIT_FULL_HOSTNAME=""
MONIT_SSH_PORT=""
MONIT_PHPFPM_SOCKET=""

# @TODO tests: init.d,  pid,  bin,  conf,  output age

Monit_enable() {
    local PLUGIN="$1"

    if ! [ -f "/etc/monit/monitrc.d/${PLUGIN}" ]; then
        echo "Plugin not found: (${PLUGIN})" >&2
        return 1
    fi

    ln -svf "/etc/monit/monitrc.d/${PLUGIN}" "/etc/monit/conf.d/${PLUGIN}" \
        || echo "Cannot create symlink" >&2
}

Monit_monit() {
    cat > "/etc/monit/monitrc.d/00_monitrc" <<EOF
set daemon 120
    with start delay ${MONIT_BOOT_DELAY}

# Alert emails
set mailserver localhost port 25, mail.szepe.net port 587
set mail-format { from: root@${MONIT_EMAIL_HOST} }
set alert root@${MONIT_EMAIL_HOST} with reminder on 2 cycle

# Web interface
set httpd port 2812 and
    use address localhost
    allow localhost
EOF
    Monit_enable 00_monitrc
}

Monit_system() {
    cat > "/etc/monit/monitrc.d/01_${MONIT_FULL_HOSTNAME}" <<MONITSYSTEM
check system ${MONIT_FULL_HOSTNAME//[^0-9A-Za-z]/_}
    if loadavg (1min) > 4 then alert
    if loadavg (5min) > 2 then alert
    if memory usage > 75% then alert
    if swap usage > 25% then alert
    if cpu usage (user) > 70% then alert
    if cpu usage (system) > 30% then alert
    if cpu usage (wait) > 20% then alert
check filesystem rootfs with path /
    if space usage > 90% then alert
MONITSYSTEM
    Monit_enable "01_${MONIT_FULL_HOSTNAME}"
}

Monit_ssh() {
    sed -i "s/port 22 with proto ssh/port ${MONIT_SSH_PORT} with proto ssh/" /etc/monit/monitrc.d/openssh-server
    Monit_enable openssh-server
}

Monit_unscd() {
    cat > "/etc/monit/monitrc.d/unscd" <<MONITUNSCD
# µNameservice caching daemon (unscd)
check process nscd with pidfile /var/run/nscd/nscd.pid
    group system
    start program = "/etc/init.d/unscd start"
    stop  program = "/etc/init.d/unscd stop"
    if 5 restarts within 5 cycles then unmonitor
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
    Monit_enable unscd
}

Monit_fail2ban() {
    cat > "/etc/monit/monitrc.d/fail2ban" <<MONITFAIL2BAN
check process fail2ban with pidfile /var/run/fail2ban/fail2ban.pid
    group services
    start program = "/etc/init.d/fail2ban force-start"
    stop  program = "/etc/init.d/fail2ban stop || :"
    if failed unixsocket /var/run/fail2ban/fail2ban.sock then restart
    if 5 restarts within 5 cycles then unmonitor

check file fail2ban_log with path /var/log/fail2ban.log
    if match "ERROR|WARNING" then alert
MONITFAIL2BAN
    Monit_enable fail2ban
}

Monit_rsyslog(){
    # @TODO --MARK--
    Monit_enable rsyslog
}

Monit_cron() {
    Monit_enable cron
}

Monit_phpfpm() {
    #     https://github.com/perusio/monit-miscellaneous
    wget -O /etc/monit/monitrc.d/php-fpm-unix \
        "https://raw.githubusercontent.com/szepeviktor/monit-miscellaneous/patch-1/php-fpm-unix"
    # @FIXME Has a bug: https://raw.githubusercontent.com/perusio/monit-miscellaneous/master/php-fpm-unix
    sed -i "s|unixsocket /var/run/php-fpm.sock then|unixsocket /var/run/${MONIT_PHPFPM_SOCKET} then|" \
        /etc/monit/monitrc.d/php-fpm-unix
    #sed -i "s|alert root@localhost only on {timeout}$|alert root@${MONIT_EMAIL_HOST} only on {timeout}|g" \
    #    /etc/monit/monitrc.d/php-fpm-unix
    sed -i "s|alert root@localhost only on {timeout}$||g" /etc/monit/monitrc.d/php-fpm-unix
    sed -i "s|alert root@localhost$||g" /etc/monit/monitrc.d/php-fpm-unix
    Monit_enable php-fpm-unix
}

Monit_couriersmtp() {
    wget -O /etc/monit/monitrc.d/courier \
        "https://raw.githubusercontent.com/szepeviktor/FladischerMichael.monit/master/courier.test"
    Monit_enable courier
}

Monit_courierauth() {
    wget -O /etc/monit/monitrc.d/courier-auth \
        "https://github.com/szepeviktor/FladischerMichael.monit/raw/master/courier-auth.test"
    Monit_enable courier-auth
}

Monit_courierimap() {
    wget -O /etc/monit/monitrc.d/courier-imap \
        "https://github.com/szepeviktor/FladischerMichael.monit/raw/master/courier-imap.test"
    Monit_enable courier-imap
}

Monit_apache() {
    Monit_enable apache2
}

Monit_mysql() {
    Monit_enable mysql
    echo 'Create DB user!'
}

[ -d /etc/monit/monitrc.d ] || exit 1
[ -z "$MONIT_BOOT_DELAY" ] && exit 2
[ -z "$MONIT_EMAIL_HOST" ] && exit 2
[ -z "$MONIT_FULL_HOSTNAME" ] && exit 2
[ -z "$MONIT_SSH_PORT" ] && exit 2
[ -z "$MONIT_PHPFPM_SOCKET" ] && exit 2

# Filename only
MONIT_PHPFPM_SOCKET="$(basename "$MONIT_PHPFPM_SOCKET")"

# Plugins
#     http://storage.fladi.at/~FladischerMichael/monit/
# Mirror: https://github.com/szepeviktor/FladischerMichael.monit
Monit_monit
Monit_system
[ -x /usr/sbin/sshd ] && Monit_ssh
[ -x /usr/sbin/nscd ] && Monit_unscd
[ -x /usr/sbin/rsyslogd ] && Monit_rsyslog
[ -x /usr/sbin/cron ] && Monit_cron
[ -x /usr/bin/fail2ban-server ] && Monit_fail2ban
[ -x /usr/sbin/php5-fpm ] && Monit_phpfpm
[ -x /usr/sbin/courieresmtpd ] && Monit_couriersmtp
[ -x /usr/lib/courier/courier-authlib/authdaemond ] && Monit_courierauth
[ -x /usr/bin/imapd ] && Monit_courierimap
[ -x /usr/sbin/apache2 ] && Monit_apache
[ -x /usr/sbin/mysqld ] && Monit_mysql

# @TODO https://extremeshok.com/5207/monit-configs-for-ubuntu-debian-centos-rhce-redhat/

#Monit_enable at
#Monit_enable memcached
#Monit_enable nginx
#Monit_enable openntpd
#Monit_enable pdns-recursor
#Monit_enable postfix
#Monit_enable snmpd

# Hardware related
#Monit_enable acpid
#Monit_enable smartmontools
#Monit_enable mdadm

# Mail related
#Monit_enable spamassassin

# Wake up monit cron job
# @TODO remove "unmonitor"-s
cat > /etc/cron.hourly/monit-wake <<EOF
#!/bin/bash

/usr/bin/monit summary | tail -n +3 \
    | grep -v "\sRunning$\|\sAccessible$" \
    | sed -ne "s;^.*'\(\S\+\)'.*$;\1;p" \
    | xargs -L 1 -r /usr/bin/monit monitor # && /usr/local/sbin/swap-refresh.sh

exit 0
EOF
chmod +x /etc/cron.hourly/monit-wake
