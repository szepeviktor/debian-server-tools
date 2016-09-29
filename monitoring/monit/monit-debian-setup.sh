#!/bin/bash
#
# Install and set up monit
#
# VERSION       :0.6.6
# DATE          :2016-05-20
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :https://mmonit.com/monit/documentation/monit.html
# DOCS          :https://mmonit.com/wiki/Monit/ConfigurationExamples

set -e

# Usage
#
# Use example defaults file or edit your own
#     install --mode=0600 -D -t /etc/monit monit.defaults
#
# Exclude packages
#     MONIT_EXCLUDED_PACKAGES=apache2:php5-fpm:php7.0-fpm ./monit-debian-setup.sh
#
# List not yet enabled service configs for installed packages
#     dpkg-query --showformat="\${Package}\n" --show | while read -r PKG; do
#     if [ -f "services/${PKG}" ] && ! [ -f "/etc/monit/conf-enabled/${PKG}" ]; then
#     echo "Missing: ${PKG}"; fi; done

# @TODO
# - integrate cert-expiry as "openssl"
# - document putty port-forward 2812+N (web interface)
# - add "/etc/init.d/SERVICE status" checks
# - list permissions: grep -i -l -m 1 "^\s*check\s" services/* | xargs ls -l

DEBIAN_SERVER_TOOLS_INSTALLER="../../install.sh"
MONIT_SERVICES="./services"
MONIT_DEFAULTS="/etc/monit/monit.defaults"

Is_pkg_installed() {
    local PKG="$1"

    [ "$(dpkg-query --showformat="\${Status}" --show "$PKG" 2> /dev/null)" == "install ok installed" ]
}

Monit_template() {
    local TPL="$1"
    local OUT="$2"
    local VARIABLES
    local VAR_NAME
    local DEFAULT_NAME
    local VALUE

    if ! install --no-target-directory --mode=0600 "$TPL" "$OUT"; then
        echo "Writing to service configuration failed (${OUT})" 1>&2
        exit 11
    fi

    VARIABLES="$(grep -o "@@[A-Z0-9_]\+@@" "$TPL" | nl | sort -k 2 | uniq -f 1 | sort -n | sed -e 's;\s*[0-9]\+\s\+;;')"
    if [ -z "$VARIABLES" ]; then
        return 0
    fi

    while read -r VAR_NAME <&3; do
        # Strip @-s
        VAR_NAME="${VAR_NAME//@@/}"
        if [[ "$VAR_NAME" =~ _DEFAULT$ ]]; then
            echo "Invalid variable name (${VAR_NAME}) in template: ${TPL}" 1>&2
            exit 10
        fi
        # _preinst script could set default value
        DEFAULT_NAME="${VAR_NAME}_DEFAULT"
        if grep -q "^${DEFAULT_NAME}=" "$MONIT_DEFAULTS"; then
            # Override with previous value
            declare "${DEFAULT_NAME}=$(sed -n -e "0,/^${DEFAULT_NAME}=\"\(.*\)\"\$/s//\1/p" "$MONIT_DEFAULTS")" #"
            # Read value into $VAR_NAME
            read -r -e -p "${VAR_NAME}=" -i "${!DEFAULT_NAME}" "$VAR_NAME"
        else
            # Read value into $VAR_NAME
            read -r -e -p "${VAR_NAME}=" -i "${!DEFAULT_NAME}" "$VAR_NAME"
            # Save value as next default
            echo "${VAR_NAME}_DEFAULT=\"${!VAR_NAME}\"" >> "$MONIT_DEFAULTS"
            chmod 0600 "$MONIT_DEFAULTS"
        fi
        VALUE="${!VAR_NAME}"
        # Escape for sed
        VALUE="${VALUE//;/\\;}"
        # Substitute variable
        sed -i -e "s;@@${VAR_NAME}@@;${VALUE};g" "$OUT"
    done 3<<< "$VARIABLES"
}

Monit_enable() {
    local SERVICE="$1"
    local -i IS_CONFIG="${2:-0}"
    local SERVICE_TEMPLATE="${MONIT_SERVICES}/${SERVICE}"

    echo "---  ${SERVICE}  ---"

    if ! [ -r "$SERVICE_TEMPLATE" ]; then
        echo "ERROR: Service template not found (${SERVICE_TEMPLATE})" 1>&2
        return 1
    fi

    # 1) _script
    if [ -r "${SERVICE_TEMPLATE}_script" ]; then
        "$DEBIAN_SERVER_TOOLS_INSTALLER" "${SERVICE_TEMPLATE}_script"
    fi

    # 2) _preinst
    if [ -r "${SERVICE_TEMPLATE}_preinst" ]; then
        source "${SERVICE_TEMPLATE}_preinst"
    fi

    # 3) Render template
    if [ "$IS_CONFIG" == 1 ]; then
        Monit_template "$SERVICE_TEMPLATE" "/etc/monit/conf.d/${SERVICE}"
    else
        Monit_template "$SERVICE_TEMPLATE" "/etc/monit/conf-available/${SERVICE}"
    fi

    # 4) _postinst
    if [ -r "${SERVICE_TEMPLATE}_postinst" ]; then
        source "${SERVICE_TEMPLATE}_postinst"
    fi

    # 5) Enable service
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
    Monit_enable 00-monitrc 1
}

Monit_system() {
    Monit_enable 01-system
    Monit_enable 02-healthchecks
}

Monit_all_packages() {
    local PACKAGES
    local PACKAGE

    PACKAGES="$(dpkg-query --showformat="\${Package}\n" --show)"

    while read -r PACKAGE <&4; do
        if [ -f "${MONIT_SERVICES}/${PACKAGE}" ] && ! grep -qF ":${PACKAGE}:" <<< ":${MONIT_EXCLUDED_PACKAGES}:"; then
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
            if Is_pkg_installed "$PACKAGE" && ! grep -qF ":${PACKAGE}:" <<< ":${MONIT_EXCLUDED_PACKAGES}:"; then
                Monit_enable "$MAIN_PACKAGE"
                break
            fi
        done
    done
}

Monit_apt_config() {
    echo "---  apt.conf  ---"

    cat > /etc/apt/apt.conf.d/05monit <<"EOF"
DPkg::Pre-Invoke { "[ -x /usr/bin/monit ] && /etc/init.d/monit stop" };
DPkg::Post-Invoke { "[ -x /usr/bin/monit ] && /etc/init.d/monit start" };
EOF
}

Monit_wake() {
    # @FIXME What a hack!

    local CRONJOB="/etc/cron.hourly/monit-wake"

    echo "---  cron.hourly  ---"

    cat > "$CRONJOB" <<"EOF"
#!/bin/bash
#
# Monit_wake
#
# VERSION       :0.7.0

# If apt is not in progress
if ! fuser /var/lib/dpkg/lock > /dev/null 2>&1; then
    # Monit is stopped
    if ! /etc/init.d/monit status | grep -qF "monit is running"; then
        echo "Monit is not responding" | mail -s "Monit ALERT on $(hostname -f)" root
        /etc/init.d/monit restart || /etc/init.d/monit start
    fi
fi

# Try remonitor failed services
IGNORED_STATUSES="Running|Accessible|Status ok|Waiting"
/usr/bin/monit -B summary | tail -n +3 \
    | grep -vE "\sSystem\s*\$|\s(${IGNORED_STATUSES})\s*\S+\s*\$" \
    | sed -n -e "s;^\s*\(\S\+\)\s\+.\+\s\+\S\+\s*\$;\1;p" \
    | xargs -r -L 1 /usr/bin/monit monitor

# Exit status 0 means it was OK
if [ $? != 0 ] && [ -x /usr/local/sbin/swap-refresh.sh ]; then
    /usr/local/sbin/swap-refresh.sh
fi

exit 0
EOF
    chmod +x "$CRONJOB"
}

Monit_start() {
    local MONIT_SYNTAX_CHECK

    echo "---  Start Monit  ---"

    MONIT_SYNTAX_CHECK="$(monit -t 2>&1)"
    if [ "$MONIT_SYNTAX_CHECK" == "Control file syntax OK" ]; then
        service monit start
        # Must equal to start delay
        # sed -n -e 's|^.*start delay \([0-9]\+\)$|\1|p' services/00-monitrc
        sleep 10
        monit summary
        echo "OK."
        echo "tail -f /var/log/monit.log"
    else
        echo "ERROR: Syntax check failed" 1>&2
        echo "$MONIT_SYNTAX_CHECK" | grep -vFx "Control file syntax OK" 1>&2
    fi
}

trap 'echo "RET=$?"' EXIT HUP QUIT PIPE TERM

if dpkg --compare-versions "$(aptitude --disable-columns search -F "%V" '?exact-name(monit)')" lt "1:5.18"; then
    echo "Minimum Monit version needed: 5.18" 1>&2
    exit 1
fi
if Is_pkg_installed systemd; then
    echo "systemd AND Monit?" 1>&2
    exit 2
fi
if ! [ -f "$MONIT_DEFAULTS" ]; then
    echo "Missing defaults file" 1>&2
    exit 3
fi
if ! Is_pkg_installed usbutils; then
    apt-get install -y usbutils
fi
if ! Is_pkg_installed monit; then
    apt-get install -t jessie-backports -y monit
fi
service monit stop || true
# Disable all services
rm -f /etc/monit/conf-enabled/*

Monit_config

Monit_system
Monit_all_packages
Monit_virtual_packages

Monit_apt_config
Monit_wake

Monit_start
