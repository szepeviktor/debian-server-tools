#!/bin/bash
#
# Configure monit plugins
#
# VERSION       :0.5.0
# DATE          :2016-05-07
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :https://mmonit.com/monit/documentation/monit.html
# DOCS          :https://mmonit.com/wiki/Monit/ConfigurationExamples
# DEPENDS       :apt-get install monit

set -e

# interfaces, resolv.conf -> checksum
# ADD serverfeatures
# ADD server-integrity
# new specific tests from links in Repo-changes.sh
#   Tests: init.d,  pid,  bin,  conf,  output age
# reinstall all servers

MONIT_SERVICES="./services"

Is_pkg_installed() {
    dpkg-query --showformat='${Status}' --show "$1" | grep -q "install ok installed"
}

Monit_template() {
    local TPL="$1"
    local OUT="$2"
    local VARIABLES
    local VAR_NAME
    local DEFAULT_NAME
    local VALUE

    if ! [ -r "$TPL" ]; then
        echo "Service template not found (${TPL})" 1>&2
        return 1
    fi
    if ! cp -f "$TPL" "$OUT"; then
        echo "Writing to service configuration failed: ${OUT}" 1>&2
        exit 11
    fi

    VARIABLES="$(grep -o "@@[A-Z0-9_]\+@@" "$TPL" | sort | uniq)"
    if [ -z "$VARIABLES" ]; then
        return 0
    fi

    while read -r VAR_NAME <&3; do
        # Strip @'s
        VAR_NAME="${VAR_NAME//@@/}"
        if [[ "$VAR_NAME" =~ _DEFAULT$ ]]; then
            echo "Invalid variable name (${VAR_NAME}) in template: ${TPL}"
            exit 10
        fi
        DEFAULT_NAME="${VAR_NAME}_DEFAULT"

        read -r -e -p "${VAR_NAME}=" -i "${!DEFAULT_NAME}" VALUE

        # Escape for sed
        VALUE="${VALUE//;/\\;}"
        # Substitute variables
        sed -i -e "s;@@${VAR_NAME}@@;${VALUE};g" "$OUT"
    done 3<<< "$VARIABLES"
}

Monit_apt_config() {
    cat > /etc/apt/apt.conf.d/05monit <<EOF
DPkg::Pre-Invoke { "[ -x /usr/bin/monit ] && /etc/init.d/monit stop" };
DPkg::Post-Invoke { "[ -x /usr/bin/monit ] && /etc/init.d/monit start" };
EOF
}

Monit_enable() {
    local SERVICE="$1"
    local -i IS_CONFIG="${2:-0}"
    local SERVICE_TEMPLATE="${MONIT_SERVICES}/${SERVICE}"

    echo "---  ${SERVICE}  ---"

    if ! [ -r "$SERVICE_TEMPLATE" ]; then
        echo "Service template not found (${SERVICE_TEMPLATE})" 1>&2
        return 1
    fi

    # 1) .preinst
    if [ -r "${SERVICE_TEMPLATE}.preinst" ]; then
        source "${SERVICE_TEMPLATE}.preinst"
    fi

    # 2) .script
    if [ -r "${SERVICE_TEMPLATE}.script" ]; then
        # @FIXME Where to install install.sh?
        ../../install.sh "${SERVICE_TEMPLATE}.script"
    fi

    # 3) Apply template
    Monit_template "$SERVICE_TEMPLATE" "/etc/monit/conf-available/${SERVICE}"

    # 4) .postinst
    if [ -r "${SERVICE_TEMPLATE}.postinst" ]; then
        source "${SERVICE_TEMPLATE}.postinst"
    fi

    # 5) Symlink
    if [ "$IS_CONFIG" != 1 ] && ! ln -svf "../conf-available/${SERVICE}" /etc/monit/conf-enabled/; then
        echo "Failed to enable service (${SERVICE})" 1>&2
        exit 20
    fi

    return 0
}

Monit_config() {
    # IS_CONFIG=1
    Monit_enable 00_monitrc 1
}

Monit_system() {
    Monit_enable 01_system
}

Monit_all_packages() {
    local PACKAGES="$(dpkg-query -W -f '${Package}\n')"
    local PACKAGE

    while read -r PACKAGE <&4; do
        if [ -f "${MONIT_SERVICES}/${PACKAGE}" ]; then
            Monit_enable "$PACKAGE"
        fi
    done 4<<< "$PACKAGES"
}

Monit_wake() {
    # @FIXME What a hack!

    local CRONJOB="/etc/cron.hourly/monit-wake"

    cat > "$CRONJOB" <<EOF
#!/bin/bash

# @TODO echo 'Alert!!'

/usr/bin/monit summary | tail -n +3 \
    | grep -vE "\sRunning$|\sAccessible$|\sStatus ok$" \
    | sed -n -e "s;^.*'\(\S\+\)'.*$;\1;p" \
    | xargs -r -L 1 /usr/bin/monit monitor

# RET=0 -> There was a failure
if [ $? == 0 ] && [ -x /usr/local/sbin/swap-refresh.sh ]; then
    /usr/local/sbin/swap-refresh.sh
fi

exit 0
EOF
    chmod +x "$CRONJOB"
}

Monit_mysql() {
    if [ -f /etc/monit/conf-enabled/mysql-server ]; then
        return 0
    fi

    # Packages for mysql-server
    if Is_pkg_installed mariadb-server \
        || Is_pkg_installed mariadb-server-10.0 \
        || Is_pkg_installed mysql-server-5.6; then
        Monit_enable mysql-server
    fi
}

Monit_nginx() {
    # @TODO
    # Packages for nginx
}

if ! Is_pkg_installed monit; then
    apt-get install -q -y monit
fi

Monit_config

Monit_system
Monit_all_packages
Monit_mysql
Monit_nginx

Monit_apt_config

Monit_wake
