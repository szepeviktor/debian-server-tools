#!/bin/bash
#
# Install munin node.
#

# @REWRITE: install&configure plugins per debian pkg, 
# apt-get install munin-plugin-mysql
#
# +plugins https://packages.debian.org/source/experimental/munin  v2.999.x
#     https://anonscm.debian.org/git/collab-maint/munin.git
# test for each plugin bundle:
always: munin-plugins-core
nc -v -z -u localhost 53 munin-plugins-dns
always: munin-plugins-extra
munin-plugins-http
munin-plugins-irc
munin-plugins-jenkins
munin-plugins-ldap
munin-plugins-mail
hash mysql munin-plugins-mysql
munin-plugins-network
munin-plugins-pgsql
munin-plugins-snmp
munin-plugins-time
# +plugins https://github.com/munin-monitoring/contrib
# +plugins: local one from debian-server-tools
# Prefer /usr/local/share/ plugins! Disable same plugin from Debian /usr/share/


MUNIN_MASTER_IP="1.2.3.4"

LOADTIME_URL="http://www.site.net/login"
PHPFPM_POOL="web"
PHPFPM_STATUS="http://www.site.net/statusphp"
APACHE_STATUS="http://www.site.net:%d/server-status?auto"

PLUGIN_CONF_DIR="/etc/munin/plugin-conf.d"
PLUGIN_PATH="/usr/share/munin/plugins"
PLUGIN_PATH_LOCAL="/usr/local/share/munin/plugins"
ENABLED_PLUGIN_PATH="/etc/munin/plugins"

# Plugin types
#     http://guide.munin-monitoring.org/en/latest/architecture/syntax.html

# munin cron += /usr/bin/nice

# non-autoconf + /usr/local/share/munin/plugins/* -> write .config and .script

# Does autoconf/suggest work?
#     munin-node-configure --families auto,manual,contrib --suggest 2>&1 | less
#     munin-node-configure --families auto,manual,contrib --suggest --debug 2>&1 | less


# - official auto (always has autoconf)
#     detect "auto but not non autoconf"
#         cd /usr/share/munin/plugins
#         munin-node-configure --families auto|tail -n +3|cut -d' ' -f1|xargs -L1 grep -HL "#%# capabilities=.*autoconf"
#     find fake/modified official auto-s:
#         munin-node-configure --libdir /usr/local/share/munin/plugins --families auto
###       ?How to handle ?Exclude the one with same name in /usr/share/munin/plugins
# - contrib
#     detect autoconf
#         cd /usr/share/munin/plugins
#         munin-node-configure --families contrib|tail -n +3|cut -d' ' -f1|xargs -L1 grep -H "#%# capabilities=.*autoconf"
#     detect non-autoconf
#         cd /usr/share/munin/plugins
#         munin-node-configure --families contrib|tail -n +3|cut -d' ' -f1|xargs -L1 grep -HL "#%# capabilities=.*autoconf"
# - manual
#     detect autoconf
#         cd /usr/share/munin/plugins
#         munin-node-configure --families manual|tail -n +3|cut -d' ' -f1|xargs -L1 grep -H "#%# capabilities=.*autoconf"
#     detect non-autoconf
#         cd /usr/share/munin/plugins
#         munin-node-configure --families manual|tail -n +3|cut -d' ' -f1|xargs -L1 grep -HL "#%# capabilities=.*autoconf"
# - wildcard: All suggest-s should be autoconf also
# - wildcard: Fix non-suggest-s to be suggest
# - missing familiy magic markers (send PR to munin)
#         cd /usr/share/munin/plugins
#         munin-node-configure|tail -n +3|cut -d' ' -f1|xargs -L1 grep -HL "#%# family"


# http://munin-monitoring.org/wiki/munin-node-configure
# deb-name -> plugin name mapping Yes!

# source and use $MUNIN_LIBDIR/plugins/plugin.sh
# script names = PLUGIN_NAME.script
# config: /etc/munin/plugin-conf.d/${PLUGIN_NAME}
# HTTP_LOADTIME_URLS multiple|multiple
# Bash suggest example

# 0. /usr/local/src/debian-server-tools/monitoring/munin/plugins
# 1. /usr/local/src/debian-server-tools/monitoring/munin/munin-debian/plugins/node.d
# 2. /usr/local/src/debian-server-tools/monitoring/munin/munin-debian/plugins/node.d.linux
# 3. /usr/local/src/debian-server-tools/monitoring/munin/contrib/plugins


munin-node-configure --libdir /usr/local/share/munin/plugins --families auto,manual,contrib \
    --suggest 2>&1
munin-node-configure --libdir /usr/local/share/munin/plugins --families auto,manual,contrib \
    --shell --debug 2>&1


Munin_packages2plugins()
{
# Invent a "depends" mechanism for plugins: have a list: plugin->apt:depends|pip:depends...
    local -A PACKAGES=(
        [coreutils]="df:df_inode"
        [apache2]="apache:http_loadtime"
        [courier-mta]="courier_mta_mailqueue:courier_mta_mailstats:courier_mta_mailvolume"
        [ipmitool]="ipmi_sensor_"
        [monit]="monit_parser"
        [munin]="munin_events" # needs logtail
        [rsyslog]="loggrep"
        [memcached]="memcached_"
    )

    echo "${PACKAGES[@]}"
}

Install_plugin()
{
    local PLUGIN_URL="$1"
    local PLUGIN_NAME

    PLUGIN_NAME="$(basename "$PLUGIN_URL")"
    [ -d "$PLUGIN_PATH_LOCAL" ] || mkdir -p "$PLUGIN_PATH_LOCAL"

    if ! wget -nv -O "${PLUGIN_PATH_LOCAL}/${PLUGIN_NAME}" "$PLUGIN_URL"; then
        echo "ERROR: plugin ${PLUGIN_NAME} download failure" 1>&2
        return 1
    fi
    chmod 755 "${PLUGIN_PATH_LOCAL}/${PLUGIN_NAME}"

    # Separator
    echo
}

Enable_plugin()
{
    local PLUGIN_NAME="$1"
    local PLUGIN_ALIAS="$2"
    local ACTUAL_PATH

    [ -z "$PLUGIN_ALIAS" ] && PLUGIN_ALIAS="$PLUGIN_NAME"

    if [ -f "${PLUGIN_PATH}/${PLUGIN_NAME}" ]; then
        ACTUAL_PATH="${PLUGIN_PATH}/${PLUGIN_NAME}"
    elif [ -f "${PLUGIN_PATH_LOCAL}/${PLUGIN_NAME}" ]; then
        ACTUAL_PATH="${PLUGIN_PATH_LOCAL}/${PLUGIN_NAME}"
    else
        echo "ERROR: plugin does not exist: ${PLUGIN_NAME}" >&2
        return 1
    fi

    if ! ln -sfv "$ACTUAL_PATH" "${ENABLED_PLUGIN_PATH}/${PLUGIN_ALIAS}"; then
        echo "ERROR: plugin enabling error, alias: ${PLUGIN_ALIAS}" >&2
        return 2
    fi
}

munin_events()
{
    # For munin master only
    [ -x /usr/bin/munin-cron ] || return 1

    if ! which logtail2 &>/dev/null; then
        echo "ERROR: logtail2 is missing  apt-get install -y logtail"
        return 1
    fi

    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/munin_events"
    cat >"${PLUGIN_CONF_DIR}/munin_events" <<MUNIN_EVENTS_CONF
[munin_events]
user munin
env.munin_fatal_critical 0
env.munin_error_critical 0
env.munin_warning_warning 0
env.munin_warning_critical 5
MUNIN_EVENTS_CONF
}

munin_monit()
{
    [ -x /usr/bin/monit ] || return 1

#    Install_plugin "https://github.com/munin-monitoring/contrib/raw/master/plugins/monit/monit_parser"
    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/monit_parser"
    cat >"${PLUGIN_CONF_DIR}/monit_parser" <<EOF
[monit_parser]
user root
EOF
    Enable_plugin "monit_parser"
}


munin_mysql()
{
    if ! dpkg -l libmodule-pluggable-perl libdbd-mysql-perl &>/dev/null; then
        echo "ERROR: libmodule-pluggable-perl or libdbd-mysql-perl missing," 1>&2
        echo "ERROR: apt-get install -y libmodule-pluggable-perl libdbd-mysql-perl" 1>&2
        return 2
    fi

    # Upstream: https://github.com/kjellm/munin-mysql
    wget "https://github.com/kjellm/munin-mysql/archive/master.zip"
    unzip munin-mysql*.zip
    cd munin-mysql-master/ || return 1
    touch "${PLUGIN_CONF_DIR}/mysql.conf"
    make install
}

munin_ipmi()
{
    which ipmitool &>/dev/null || return 1

    cat >"${PLUGIN_CONF_DIR}/ipmi" <<IPMI_PLG
[ipmi_sensor2_*]
user root
timeout 20
IPMI_PLG

    cat >"/etc/munin/ipmi" <<IPMI_CFG
# ipmitool sensor list
rpm = CPU FAN, SYSTEM FAN
volts = System 12V, System 5V, System 3.3V, CPU0 Vcore, System 1.25V, System 1.8V, System 1.2V
degrees_c = CPU0 Dmn 0 Temp
IPMI_CFG

    Install_plugin "https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/munin/ipmi_sensor2_"
}

munin_fail2ban()
{
    which fail2ban-client &>/dev/null || return 1

    cat >"${PLUGIN_CONF_DIR}/fail2ban" <<EOF
[fail2ban]
user root
EOF
}

munin_loadtime()
{
    [ "$LOADTIME_URL" == "http://www.site.net/login" ] && return 1
    [ -z "$LOADTIME_URL" ] && return 1

    cat >"${PLUGIN_CONF_DIR}/http_loadtime" <<EOF
[http_loadtime]
env.target ${LOADTIME_URL}
EOF
}

munin_multiping()
{
    cat >"${PLUGIN_CONF_DIR}/multiping" <<EOF
[multiping]
#     http://lg.net.telekom.hu/
#     http://lg.invitel.net/
#        Telekom         UPC             DIGI            Invitel
env.host 84.3.64.1       84.116.240.33   94.21.3.57      217.113.63.72
EOF

    Enable_plugin "multiping"
}

munin_startcom()
{
    local STARTCOM_IP

    # ocsp.startssl.com
    STARTCOM_IP="$(host -t A ocsp.startssl.com|sed -n -e '0,/^.* has address \(.\+\)$/s//\1/p')"

    if ! ping -c 3 "$STARTCOM_IP"; then
        echo "ERROR: No connection with StartCom" 1>&2
        return 1
    fi

    Enable_plugin "ping_" "ping_${STARTCOM_IP}"
}

munin_decix()
{
    local DECIX_IP="80.81.192.1"

    if ! ping -c 3 "$DECIX_IP"; then
        echo "ERROR: No DE-CIX connection" 1>&2
        return 1
    fi

    # DE-CIX
    Enable_plugin "ping_" "ping_${DECIX_IP}"
}

munin_phpfpm()
{
    # https://github.com/tjstein/php5-fpm-munin-plugins

    [ -x /usr/sbin/php5-fpm ] || return 1

    if ! dpkg -l libwww-perl &>/dev/null; then
        echo "ERROR: libwww-perl missing,  apt-get install -y libwww-perl" 1>&2
        return 2
    fi

    # phpfpm pool:
    # pm.status_path = /statusphp

    # Apache 2.4 config:
    # <Location /statusphp>
    #     SetHandler application/x-httpd-php
    #     Require local
    # </Location>

    # WordPress rewrite rule:
    # RewriteCond %{REQUEST_URI} !=/statusphp

    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_average"
    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_connections"
    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_memory"
    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_processes"
    Install_plugin "https://github.com/tjstein/php5-fpm-munin-plugins/raw/master/phpfpm_status"

    cat >"${PLUGIN_CONF_DIR}/phpfpm" <<PHP_FPM
[phpfpm_*]
env.phpbin php-fpm
env.phppool ${PHPFPM_POOL}
env.url ${PHPFPM_STATUS}
PHP_FPM

    cat 1>&2 <<APACHE_CNF
# Terminate rewrite processing for PHP-FPM status
<Location /statusphp>
    SetHandler application/x-httpd-php
    Require local
</Location>
RewriteEngine On
RewriteRule "^/statusphp\$" - [END]
APACHE_CNF

    Enable_plugin "phpfpm_memory"
    # @TODO Rewrite PHP plugins: add autoconf
}

munin_apache()
{
    [ -x /usr/sbin/apache2 ] || return 1

    cat >"${PLUGIN_CONF_DIR}/apache" <<EOF
[apache_*]
env.url ${APACHE_STATUS}
EOF

    cat 1>&2 <<EOF
# Terminate rewrite processing for Apache status
<IfModule mod_status.c>
    <Location /server-status>
        SetHandler server-status
        Require local
    </Location>
    RewriteEngine On
    RewriteRule "^/server-status$" - [END]
</IfModule>

# Comment out '<Location /server-status>' block
editor /etc/apache2/mods-available/status.conf
EOF
}

# @TODO https://www.monitis.com/monitoring-plan-builder
# Ideas: URL hit, load, SMS

apt-get install -y liblwp-useragent-determined-perl libcache-cache-perl \
    libmodule-pluggable-perl libdbd-mysql-perl libwww-perl libcrypt-ssleay-perl \
    time logtail munin-node

# Dependency
which munin-node-configure &>/dev/null || exit 99

# Monitor monitoring
munin_events
munin_monit

# Hardware
#     https://github.com/munin-monitoring/contrib/tree/master/plugins/sensors
# @TODO https://github.com/munin-monitoring/contrib/raw/master/plugins/sensors/hwmon
#munin_hwmon
munin_ipmi
ln -svf /usr/local/share/munin/plugins/ipmi_sensor2_ /etc/munin/plugins/ipmi_sensors2_u_degrees_c
ln -svf /usr/local/share/munin/plugins/ipmi_sensor2_ /etc/munin/plugins/ipmi_sensors2_u_volts
ln -svf /usr/local/share/munin/plugins/ipmi_sensor2_ /etc/munin/plugins/ipmi_sensors2_u_rpm

# @TODO virtual machine speed (sysbench*100) test: KVM, Xen, VZ, VMware

# Hypervisor: https://github.com/munin-monitoring/contrib/tree/master/plugins/virtualization

# Daemons
munin_mysql
munin_fail2ban
munin_loadtime
#munin_proftpd https://github.com/munin-monitoring/contrib/tree/master/plugins/ftp

# Network
munin_multiping
munin_startcom
munin_decix

#https://github.com/munin-monitoring/munin/tree/devel/plugins/node.d.linux
#munin_fw_conntrack
# apt-get install conntrack && modprobe nf_conntrack && echo "nf_conntrack" >> /etc/modules
# tcp
# traffic: ip_ 1 address 8.8.8.8??, ntp
# port_ udp 53

# Manual action needed
munin_apache
munin_phpfpm
#https://github.com/munin-monitoring/contrib/tree/master/plugins/php
# munin_phpapc https://github.com/vivid-planet/munin-php-apc
# munin_phpopcache

# Shell plugin functions
#     /usr/share/munin/plugins/plugin.sh

# Separator
echo

munin-node-configure --families auto,manual --shell
echo
# Custom plugins
munin-node-configure --libdir /usr/local/share/munin/plugins --families auto,manual,contrib --shell

echo "munin-node-configure --libdir /usr/local/share/munin/plugins --families auto,manual,contrib --shell --debug 2>&1|most"
echo '# Enable plugins by hand'
echo "Hit Ctrl+D to continue setup"
bash

echo '# Review services to mintor'
ps aux
ls -l /etc/munin/plugins
echo "Hit Ctrl+D to continue setup"
bash

# Check plugins
find /etc/munin/plugins/ -type f \
    | while read -r P; do
        if ! munin-run "$P" config; then
            echo "ERROR ${P} config status=$?"
            sleep 4
        elif ! munin-run "$P"; then
            echo "ERROR ${P} fetch status=$?"
            sleep 4
        fi
    done

# Allow munin server access
printf '\nallow ^%s$\n' "${MUNIN_MASTER_IP//./\\.}" >>/etc/munin/munin-node.conf
service munin-node restart

# Add node to the **server**
cat <<EOF
[$(hostname -f)]
    address $(ip addr show dev eth0|sed -ne 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p')
    use_node_name yes
    contacts sms
    #contacts email

# Execute on munin server
editor /etc/munin/munin.conf
EOF

echo "Disable apt_all cron job:  editor /etc/cron.d/munin-node"

# Debug
#     munin-run --servicedir /usr/local/share/munin/plugins --debug $PLUGIN_NAME

# git --git-dir=/root/src/munstrap.git --work-tree=/etc/munin/munstrap "$@"

# wget -O munin-plugin-mysql_0.3.1.orig.tar.gz https://github.com/kjellm/munin-mysql/archive/master.tar.gz
# tar -xf munin-plugin-mysql_0.3.1.orig.tar.gz
# mv munin-mysql-master munin-plugin-mysql
# cd munin-plugin-mysql/
# patch -p 1 < <(wget -qO- https://github.com/szepeviktor/munin-mysql/commit/4f0580a9d23a7b5754355a3216fcb32b17d69606.patch)
# dpkg-buildpackage -uc -us
