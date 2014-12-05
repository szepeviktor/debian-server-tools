#!/bin/bash

LOADTIME_URL="http://..."


PLUGIN_CONF_DIR="/etc/munin/plugin-conf.d"
PLUGIN_PATH="/usr/share/munin/plugins"
ENABLED_PLUGIN_PATH="/etc/munin/plugins"

# All installation steps
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

    wget -nv -O "${LOCAL_PLUGIN_PATH}/${PLUGIN_NAME}" "$PLUGIN_URL" || return 1
    chmod 755 "${LOCAL_PLUGIN_PATH}/${PLUGIN_NAME}"
    ln -sfv "${LOCAL_PLUGIN_PATH}/${PLUGIN_NAME}" "${PLUGIN_PATH}/"
}

munin_events() {
    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/munin_events"
}

munin_monit() {
    which monit &> /dev/null || return 1

    Install_plugin "https://github.com/munin-monitoring/contrib/raw/master/plugins/monit/monit_parser"
    cat <<< MONIT_CONF > "${PLUGIN_CONF_DIR}/monit"
[monit_parser]
user root
MONIT_CONF
}


munin_mysql() {
    # upstream: "https://github.com/munin-monitoring/munin/raw/devel/plugins/node.d/mysql_.in"
    # sed -i 's|^#!@@PERL@@$|#!/usr/bin/env perl|' mysql_
    # {name => 'Qcache_queries_in_cache', label => 'Queries in cache', type  => 'GAUGE'},
    # {name => 'Qcache_queries_in_cache', label => 'Queries in cache(k)', type  => 'GAUGE', cdef => 'Qcache_queries_in_cache,1024,/'},

    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/mysql_"
}

munin_ipmi() {
    which ipmitool &> /dev/null || return 1

    cat <<<IPMI_PLG > "${PLUGIN_CONF_DIR}/ipmi"
[ipmi_sensor_*]
user root
timeout 20
IPMI_PLG

    cat <<<IPMI_CFG > "/etc/munin/ipmi"
# ipmitool sensor list
rpm = CPU FAN, SYSTEM FAN
volts = System 12V, System 5V, System 3.3V, CPU0 Vcore, System 1.25V, System 1.8V, System 1.2V
degrees_c = CPU0 Dmn 0 Temp
IPMI_CFG
}

munin_fail2ban() {
    which fail2ban-client &> /dev/null || return 1

    cat <<<FAIL2BAN_PLG > "${PLUGIN_CONF_DIR}/fail2ban"
[fail2ban]
user root
FAIL2BAN_PLG
}

munin_loadtime() {
    [ "$LOADTIME_URL" == "http://..." ] && return 1
    [ -z "$LOADTIME_URL" ] && return 1

    cat <<<LOADTIME_PLG > "${PLUGIN_CONF_DIR}/http_loadtime"
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
#munin_apache
munin_loadtime
#munin_proftpd https://github.com/munin-monitoring/contrib/tree/master/plugins/ftp

#munin_php_fpm https://github.com/tjstein/php5-fpm-munin-plugins
#munin_php_apc
#munin_php_opcache

#munin_fw_conntrack https://github.com/munin-monitoring/munin/tree/devel/plugins/node.d.linux
#tcp
#ip_ 1 address 8.8.8.8??, ntp
#port_ udp 53
