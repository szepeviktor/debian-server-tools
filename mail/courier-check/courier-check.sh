#!/bin/bash
#
# Check Courier MTA configuration.
#
# VERSION       :0.1.1
# DATE          :2017-08-10
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :url
# CONFIG        :courier-check-authdaemonrc
# CONFIG        :courier-check-courierd-public
# CONFIG        :courier-check-courierd-satellite
# CONFIG        :courier-check-esmtpd-msa-public
# CONFIG        :courier-check-esmtpd-msa-satellite
# CONFIG        :courier-check-esmtpd-public
# CONFIG        :courier-check-esmtpd-satellite
# CONFIG        :courier-check-esmtpd-ssl-public

COURIER_USER="courier"

Check_user() {
    if dpkg --compare-versions "$(dpkg-query --show --showformat="\${Version}" courier-mta)" lt "0.75.0-19"; then
        COURIER_USER="daemon"
    fi
}

Check_config_perms() {
    # Changes to these take effect immediately
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
            echo "[ERROR] Unexpected value of ${VAR}: '${!VAR}' <> '${VALUE}'" 1>&2
            exit 11
        fi

        echo "${VAR} = '${VALUE}' ✓"
    done <<< "$EXPECTED"
}

set -e

source courier-check-authdaemonrc
source courier-check-courierd-public
source courier-check-esmtpd-public
source courier-check-esmtpd-msa-public
source courier-check-esmtpd-ssl-public
source courier-check-imapd
source courier-check-imapd-ssl-public
#source courier-check-courierd-satellite
#source courier-check-esmtpd-satellite
#source courier-check-esmtpd-msa-satellite

Check_user
Check_config_perms

# Authentication
echo "--- authdaemonrc ---"
! grep '^\s' /etc/courier/authdaemonrc
( source /etc/courier/authdaemonrc; Check_config "$COURIER_AUTHDAEMONRC_DEFAULTS"; )

# Outbound
echo "--- courierd ---"
! grep '^\s' /etc/courier/courierd
( source /etc/courier/courierd; Check_config "$COURIER_COURIERD_DEFAULTS"; )

# Inbound
echo "--- esmtpd ---"
! grep '^\s' /etc/courier/esmtpd
( source /etc/courier/esmtpd; Check_config "$COURIER_ESMTPD_DEFAULTS"; )

echo "--- esmtpd-msa ---"
! grep '^\s' /etc/courier/esmtpd-msa
( source /etc/courier/esmtpd; source /etc/courier/esmtpd-msa; Check_config "$COURIER_ESMTPD_MSA_DEFAULTS"; )

if [ -f /etc/courier/esmtpd-ssl ]; then
    echo "--- esmtpd-ssl ---"
    ! grep '^\s' /etc/courier/esmtpd-ssl
    ( source /etc/courier/esmtpd; source /etc/courier/esmtpd-ssl; Check_config "$COURIER_ESMTPD_SSL_DEFAULTS"; )
fi

if [ -f /etc/courier/imapd ]; then
    echo "--- imapd ---"
    ! grep '^\s' /etc/courier/imapd
    ( source /etc/courier/imapd-ssl; source /etc/courier/imapd; Check_config "$COURIER_IMAPD_DEFAULTS"; )
fi

if [ -f /etc/courier/imapd-ssl ]; then
    echo "--- imapd-ssl ---"
    ! grep '^\s' /etc/courier/imapd-ssl
    ( source /etc/courier/imapd; source /etc/courier/imapd-ssl; Check_config "$COURIER_IMAPD_SSL_DEFAULTS"; )
fi

# @TODO sizelimit, queuetime ...

echo "OK."
