#!/bin/bash
#
# Check Courier MTA configuration.
#
# VERSION       :0.2.2
# DATE          :2018-07-09
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# CONFIG        :./courier-check-*


Set_user() {
    COURIER_USER="courier"
    if dpkg --compare-versions "$(dpkg-query --show --showformat='${Version}' courier-mta)" lt "0.75.0-19"; then
        COURIER_USER="daemon"
    fi
}

Check_config_perms() {
    # Changes to these files take effect immediately
    sudo -u "$COURIER_USER" -- test -r /etc/courier/esmtpauthclient
    sudo -u "$COURIER_USER" -- test -r /etc/courier/esmtproutes
    sudo -u "$COURIER_USER" -- test -r /etc/courier/esmtpd.pem
    sudo -u "$COURIER_USER" -- test -r /etc/courier/dhparams.pem
}

Check_config() {
    local EXPECTED="$1"
    local LINE
    local VAR
    local VALUE

    while read -r LINE; do
        if [ -z "$LINE" ]; then
            continue
        fi

        VAR="${LINE%%=*}"
        if [ -z "$VAR" ]; then
            echo "Empty variable name in '$LINE'" 1>&2
            exit 10
        fi

        VALUE="$(eval echo -n "${LINE#*=}")"
        if [ "${!VAR}" != "$VALUE" ]; then
            echo "[$(tput setaf 1)ERROR$(tput sgr0)] Unexpected value of ${VAR}: '${!VAR}' <> '${VALUE}'" 1>&2
            # Warn only
            #return
            exit 11
        fi

        echo "${VAR} = '${VALUE}' $(tput setaf 2)✓$(tput sgr0)"
    done <<< "$EXPECTED"
}

set -e

# shellcheck disable=SC1091
source courier-check-authdaemonrc
# shellcheck disable=SC1091
source courier-check-courierd-public
# shellcheck disable=SC1091
source courier-check-esmtpd-public
# shellcheck disable=SC1091
source courier-check-esmtpd-msa-public
# shellcheck disable=SC1091
source courier-check-esmtpd-ssl-public
# shellcheck disable=SC1091
source courier-check-imapd
# shellcheck disable=SC1091
source courier-check-imapd-ssl-public
# shellcheck disable=SC1091
#source courier-check-courierd-satellite
# shellcheck disable=SC1091
#source courier-check-esmtpd-satellite
# shellcheck disable=SC1091
#source courier-check-esmtpd-msa-satellite
# shellcheck disable=SC1091
#source courier-check-esmtpd-ssl-satellite

Set_user
Check_config_perms

# Authentication
echo "--- authdaemonrc ---"
( ! grep '^\s' /etc/courier/authdaemonrc )
# shellcheck disable=SC1091
( source /etc/courier/authdaemonrc; Check_config "$COURIER_AUTHDAEMONRC_DEFAULTS"; )

# Outbound
echo "--- courierd ---"
( ! grep '^\s' /etc/courier/courierd )
# shellcheck disable=SC1091
( source /etc/courier/courierd; Check_config "$COURIER_COURIERD_DEFAULTS"; )

# Inbound
echo "--- esmtpd ---"
( ! grep '^\s' /etc/courier/esmtpd )
# shellcheck disable=SC1091
( source /etc/courier/esmtpd; Check_config "$COURIER_ESMTPD_DEFAULTS"; )

echo "--- esmtpd-msa ---"
( ! grep '^\s' /etc/courier/esmtpd-msa )
# shellcheck disable=SC1091
( source /etc/courier/esmtpd; source /etc/courier/esmtpd-msa; Check_config "$COURIER_ESMTPD_MSA_DEFAULTS"; )

if [ -f /etc/courier/esmtpd-ssl ]; then
    echo "--- esmtpd-ssl ---"
    ( ! grep '^\s' /etc/courier/esmtpd-ssl )
    # shellcheck disable=SC1091
    ( source /etc/courier/esmtpd; source /etc/courier/esmtpd-ssl; Check_config "$COURIER_ESMTPD_SSL_DEFAULTS"; )
fi

if [ -f /etc/courier/imapd ]; then
    echo "--- imapd ---"
    ( ! grep '^\s' /etc/courier/imapd )
    # shellcheck disable=SC1091
    ( source /etc/courier/imapd-ssl; source /etc/courier/imapd; Check_config "$COURIER_IMAPD_DEFAULTS"; )
fi

if [ -f /etc/courier/imapd-ssl ]; then
    echo "--- imapd-ssl ---"
    ( ! grep '^\s' /etc/courier/imapd-ssl )
    # shellcheck disable=SC1091
    ( source /etc/courier/imapd; source /etc/courier/imapd-ssl; Check_config "$COURIER_IMAPD_SSL_DEFAULTS"; )
fi

# @TODO sizelimit, queuetime ...

echo "OK."
