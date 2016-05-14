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

# ADD cert-expiry, ntp-alert
# new specific tests from links in Repo-changes.sh
# reinstall all servers
# add putty-port-forward 2812+N

# Exclude packages
#     EXCLUDED_PACKAGES=php5-fpm:apache2 ./monit-debian-setup.sh

MONIT_SERVICES="./services"

Is_pkg_installed() {
    dpkg-query --showformat='${Status}' --show "$1" 2> /dev/null | grep -q "install ok installed"
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

    # Fix ignored "include"-s by literally including templates (before "return 0")
    find /etc/monit/templates/ -type f \
        | while read -r TFILE; do
            TCONTENT="$(sed -e ':a;N;$!ba;s/^/  /;s/\n/\\n  /g' "$TFILE")"
            sed -i -e "s;^\s*include\s\+${TFILE}\s*$;${TCONTENT};" "$OUT"
        done

    VARIABLES="$(grep -o "@@[A-Z0-9_]\+@@" "$TPL" | nl | sort -k 2 | uniq -f 1 | sort -n | sed -e 's;\s*[0-9]\+\s\+;;')"
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

    # 1) .script
    if [ -r "${SERVICE_TEMPLATE}.script" ]; then
        # @FIXME Where to install install.sh?
        ../../install.sh "${SERVICE_TEMPLATE}.script"
    fi

    # 2) .preinst
    if [ -r "${SERVICE_TEMPLATE}.preinst" ]; then
        source "${SERVICE_TEMPLATE}.preinst"
    fi

    # 3) Render template
    if [ "$IS_CONFIG" == 1 ]; then
        Monit_template "$SERVICE_TEMPLATE" "/etc/monit/conf.d/${SERVICE}"
    else
        Monit_template "$SERVICE_TEMPLATE" "/etc/monit/conf-available/${SERVICE}"
    fi

    # 4) .postinst
    if [ -r "${SERVICE_TEMPLATE}.postinst" ]; then
        source "${SERVICE_TEMPLATE}.postinst"
    fi

    # 5) Symlink
    if [ "$IS_CONFIG" == 1 ]; then
        echo "/etc/monit/conf.d/${SERVICE}"
    else
        if ! ln -svf "../conf-available/${SERVICE}" /etc/monit/conf-enabled/; then
            echo "Failed to enable service (${SERVICE})" 1>&2
            exit 20
        fi
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
    local PACKAGES="$(dpkg-query --showformat='${Package}\n' --show)"
    local PACKAGE

    while read -r PACKAGE <&4; do
        if [ -f "${MONIT_SERVICES}/${PACKAGE}" ] && ! grep -qF ":${PACKAGE}:" <<< ":${EXCLUDED_PACKAGES}:"; then
            Monit_enable "$PACKAGE"
        fi
    done 4<<< "$PACKAGES"
}

Monit_virtual_packages() {
    local -A VPACKAGES=(
        [mysql-server]="mariadb-server,mariadb-server-10.0,mysql-server-5.6"
        [nginx]="nginx-extras,nginx-full,nginx-light"
    )
    local MAIN_PACKAGE
    local PACKAGE

    for MAIN_PACKAGE in "${!VPACKAGES[@]}"; do
        if [ -f "/etc/monit/conf-enabled/${MAIN_PACKAGE}" ]; then
            continue
        fi
        for PACKAGE in ${VPACKAGES[$MAIN_PACKAGE]//,/ }; do
            if Is_pkg_installed "$PACKAGE"; then
                Monit_enable "$MAIN_PACKAGE"
                break
            fi
        done
    done
}

Monit_wake() {
    # @FIXME What a hack!

    local CRONJOB="/etc/cron.hourly/monit-wake"

    cat > "$CRONJOB" <<EOF
#!/bin/bash

# @TODO echo 'Alert!!'

/usr/bin/monit summary | tail -n +3 \
    | grep -vE "\sRunning$|\sAccessible$|\sStatus ok$|\sWaiting$" \
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

trap 'echo "RET=$?"' EXIT HUP INT QUIT PIPE TERM

if dpkg --compare-versions "$(aptitude --disable-columns search -F "%V" '?exact-name(monit)')" lt "1:5.17.1"; then
    echo "Minimum Monit version needed: 5.17.1"
    exit 1
fi
if Is_pkg_installed systemd; then
    echo "Systemd AND Monit?"
    exit 2
fi
if ! Is_pkg_installed monit; then
    apt-get install -q -y monit
fi
service monit stop || true

Monit_config

Monit_system
Monit_all_packages
Monit_virtual_packages

Monit_apt_config
Monit_wake

service monit start
sleep 3
monit summary
echo "OK."
