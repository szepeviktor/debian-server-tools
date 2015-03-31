#!/bin/bash

LOADTIME_URL="http://www.site.net/login"
PHPFPM_POOL="web"
PHPFPM_STATUS="http://www.site.net/status"
APACHE_STATUS="http://www.site.net:%d/server-status?auto"

PLUGIN_CONF_DIR="/etc/munin/plugin-conf.d"
PLUGIN_PATH="/usr/share/munin/plugins"
ENABLED_PLUGIN_PATH="/etc/munin/plugins"

# All installation steps
#
#apt-get install -y time liblwp-useragent-determined-perl libcache-cache-perl
#apt-get install -t wheezy-backports -y munin-node
## enable plugins by hand
#munin-node-configure --shell
## review plugins
#ls -l /etc/munin/plugins
## check plugins
#ls /etc/munin/plugins/|while read P;do if ! munin-run "$P" config;then echo "ERROR ${P} config status=$?";sleep 4;
#    elif ! munin-run "$P";then echo "ERROR ${P} fetch status=$?";sleep 4;fi;done
## allow munin server IP in node config
## regexp IP address: ^1\.2\.3\.4$
#e /etc/munin/munin-node.conf
#service munin-node restart

Install_plugin() {
    local PLUGIN_URL="$1"
    local PLUGIN_NAME="$(basename "$PLUGIN_URL")"
    local LOCAL_PLUGIN_PATH="/usr/local/share/munin/plugins"

    [ -d "$LOCAL_PLUGIN_PATH" ] || mkdir -p "$LOCAL_PLUGIN_PATH"

    if ! wget -nv -O "${LOCAL_PLUGIN_PATH}/${PLUGIN_NAME}" "$PLUGIN_URL"; then
        echo "ERROR: plugin ${PLUGIN_NAME} download failure" >&2
        return 1
    fi
    chmod 755 "${LOCAL_PLUGIN_PATH}/${PLUGIN_NAME}"
    if ! ln -sfv "${LOCAL_PLUGIN_PATH}/${PLUGIN_NAME}" "${PLUGIN_PATH}/"; then
        echo "ERROR: local plugin ${PLUGIN_NAME} symlinking error" >&2
        return 2
    fi

    # separator
    echo
}

Enable_manual_plugin() {
    local PLUGIN_NAME="$1"
    local PLUGIN_ALIAS="$2"

    [ -z "$PLUGIN_ALIAS" ] && PLUGIN_ALIAS="$PLUGIN_NAME"

    if ! ln -sfv "${PLUGIN_PATH}/${PLUGIN_NAME}" "${ENABLED_PLUGIN_PATH}/${PLUGIN_ALIAS}"; then
        echo "ERROR: plugin enabling error, alias: ${PLUGIN_ALIAS}" >&2
        return 1
    fi
}

munin_events() {
    # for munin master only
    [ -x /usr/bin/munin-cron ] || return 1

    if ! which logtail2 &> /dev/null; then
        echo "ERROR: logtail2 is missing apt-get install -y logtail"
        return 1
    fi

    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/munin_events"
}

munin_monit() {
    which monit &> /dev/null || return 1

    Install_plugin "https://github.com/munin-monitoring/contrib/raw/master/plugins/monit/monit_parser"
    cat > "${PLUGIN_CONF_DIR}/monit" <<MONIT_CONF
[monit_parser]
user root
MONIT_CONF

    Enable_manual_plugin "monit_parser"
}


munin_mysql() {
    # upstream: "https://github.com/munin-monitoring/munin/raw/devel/plugins/node.d/mysql_.in"
    # sed -i 's|^#!@@PERL@@$|#!/usr/bin/env perl|' mysql_
    # mv mysql_ mysql2_
    # {name => 'Qcache_queries_in_cache', label => 'Queries in cache', type  => 'GAUGE'},
    # {name => 'Qcache_queries_in_cache', label => 'Queries in cache(k)', type  => 'GAUGE', cdef => 'Qcache_queries_in_cache,1024,/'},

    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/mysql2_"
}

munin_ipmi() {
    which ipmitool &> /dev/null || return 1

    cat > "${PLUGIN_CONF_DIR}/ipmi" <<IPMI_PLG
[ipmi_sensor2_*]
user root
timeout 20
IPMI_PLG

    cat > "/etc/munin/ipmi" <<IPMI_CFG
# ipmitool sensor list
rpm = CPU FAN, SYSTEM FAN
volts = System 12V, System 5V, System 3.3V, CPU0 Vcore, System 1.25V, System 1.8V, System 1.2V
degrees_c = CPU0 Dmn 0 Temp
IPMI_CFG

    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/ipmi_sensor2_"
}

munin_fail2ban() {
    which fail2ban-client &> /dev/null || return 1

    cat > "${PLUGIN_CONF_DIR}/fail2ban" <<FAIL2BAN_PLG
[fail2ban]
user root
FAIL2BAN_PLG
}

munin_loadtime() {
    [ "$LOADTIME_URL" == "http://..." ] && return 1
    [ -z "$LOADTIME_URL" ] && return 1

    cat > "${PLUGIN_CONF_DIR}/http_loadtime" <<LOADTIME_PLG
[http_loadtime]
env.target ${LOADTIME_URL}
LOADTIME_PLG
}

munin_courier_mta() {
    [ -x /usr/sbin/courier ] || return 1

    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/courier_mta_mailqueue"
    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/courier_mta_mailstats"
    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/courier_mta_mailvolume"
}

munin_multiping() {
    cat > "${PLUGIN_CONF_DIR}/multiping" <<MULTIPING
[multiping]
# one hop away from BIX
#        telekom,     upc,          digi,      invitel
env.host 81.183.0.151 89.135.214.78 94.21.3.57 217.113.63.72
MULTIPING

    Enable_manual_plugin "multiping"
}

munin_bix() {
    # BIX/HE
    Enable_manual_plugin "ping_" "ping_193.188.137.175"
}

munin_phpfpm() {
    # https://github.com/tjstein/php5-fpm-munin-plugins

    [ -x /usr/sbin/php5-fpm ] || return 1

    if ! dpkg -l libwww-perl &> /dev/null; then
        echo "ERROR: libwww-perl missing,  apt-get install -y libwww-perl" >&2
        return 2
    fi

    # phpfpm pool:
    # pm.status_path = /status

    # apach 2.4 config:
    # <Location /status>
    #     SetHandler application/x-httpd-php
    #     Require local
    # </Location>

    # WordPress rewrite rule:
    # RewriteCond %{REQUEST_URI} !=/status

    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_average"
    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_connections"
    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_memory"
    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_processes"
    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_status"

    cat > "${PLUGIN_CONF_DIR}/phpfpm" <<PHP_FPM
[phpfpm_*]
env.phpbin php-fpm
env.phppool ${PHPFPM_POOL}
env.url ${PHPFPM_STATUS}
PHP_FPM

    cat >&2 <<APACHE_CNF
# terminate rewrite processing for php-fpm status
<Location /status>
    SetHandler application/x-httpd-php
    Require local
    RewriteEngine on
    RewriteRule ^/status$ - [END]
</Location>
APACHE_CNF

    Enable_manual_plugin "phpfpm_average"
    # phpfpm_connections has autoconf
    Enable_manual_plugin "phpfpm_memory"
    Enable_manual_plugin "phpfpm_processes"
    # phpfpm_status has autoconf
    #TODO: rewrite 5 plugins: add autoconf
}

munin_apache() {
    cat > "${PLUGIN_CONF_DIR}/apache" <<APACHE
[apache_*]
env.url ${APACHE_STATUS}
APACHE

    cat >&2 <<APACHE_CONF
# terminate rewrite processing for apache status
<IfModule mod_status.c>
    <Location /server-status>
        SetHandler server-status
        Require local
        RewriteEngine On
        RewriteRule ^/server-status$ - [END]
    </Location>
</IfModule>
APACHE_CONF
}

#https://www.monitis.com/monitoring-plan-builder
#uptime
#URL hit
#load
#SMS

which munin-node-configure &> /dev/null || exit 99

# monitor monitoring
munin_events
munin_monit

# hardware
# https://github.com/munin-monitoring/contrib/tree/master/plugins/sensors
#TODO https://github.com/munin-monitoring/contrib/raw/master/plugins/sensors/hwmon
#munin_hwmon
munin_ipmi
#TODO virtual machines: KVM, Xen, VZ, VMware

# daemons
munin_mysql
munin_fail2ban
munin_courier_mta
munin_apache
munin_loadtime
#munin_proftpd https://github.com/munin-monitoring/contrib/tree/master/plugins/ftp

munin_phpfpm
#https://github.com/munin-monitoring/contrib/tree/master/plugins/php
    #munin_phpapc
    #munin_phpopcache

munin_multiping
munin_bix

#https://github.com/munin-monitoring/munin/tree/devel/plugins/node.d.linux
#munin_fw_conntrack
    #tcp
    #traffic: ip_ 1 address 8.8.8.8??, ntp
    #port_ udp 53

echo
munin-node-configure --shell
