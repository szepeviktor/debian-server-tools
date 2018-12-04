#!/bin/bash
#
# Check specified S.M.A.R.T. attributes of all hard drives and SSD-s.
#
# VERSION       :0.3.2
# DATE          :2015-05-16
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install s-nail smartmontools
# LOCATION      :/usr/local/sbin/smart-zeros.sh
# CRON-HOURLY   :/usr/local/sbin/smart-zeros.sh

# Manual check:
#     smartctl -A <DEVICE>
# Only /dev/sd* and /dev/hd* devices are detected.
#
# These attributes must have zero raw value:
#       1 Raw_Read_Error_Rate
#       5 Reallocated_Sector_Ct
#       7 Seek_Error_Rate
#      10 Spin_Retry_Count
#      11 Calibration_Retry_Count
#     196 Reallocated_Event_Count
#     197 Current_Pending_Sector
#     198 Offline_Uncorrectable
#     199 UDMA_CRC_Error_Count
#     200 Multi_Zone_Error_Rate
ZERO_ATTRS=( 1 5 7 10 11 196 197 198 199 200 )
ALERT_ADDRESS="root"

# List tolerated errors in form of DEVICE:ATTRIBUTE=VALUE
# Example: SILENCED_ATTRS=( /dev/sda:200=1 /dev/sdb:199=10 )
SILENCED_ATTRS=( )

Smart_error()
{
    local MESSAGE="$1"
    local LEVEL="${2:-ERROR}"

    logger -t "smart-zeros [$$]" "$MESSAGE"

    if [ -t 0 ]; then
        echo "[${LEVEL}] ${MESSAGE}" 1>&2
    else
        echo "$MESSAGE" \
            | s-nail -S "hostname=" -S from="s.m.a.r.t. zeros <root>" -s "[${LEVEL}] S.M.A.R.T. error on $(hostname --fqdn)" "$ALERT_ADDRESS"
    fi
}

Check_zero()
{
    local SMART_ATTRS="$1"
    local ATTR="$2"
    local VALUE

    # Raw value is in the 10th column
    VALUE="$(grep "^${ATTR}\\b" <<<"$SMART_ATTRS" | cut -d " " -f 10)"

    # Not found
    test -z "$VALUE" && return 2

    # OK
    if [ "$VALUE" == 0 ]; then
        return 0
    fi

    # Non-zero value
    return 1
}

which smartctl mail &>/dev/null || exit 99

# /dev/sd* and /dev/hd*
# shellcheck disable=SC2013
for DRIVE in $(grep -o '\b[hs]d[a-z]$' /proc/partitions); do
    DEVICE="/dev/${DRIVE}"

    if ! smartctl --info "$DEVICE" &>/dev/null; then
        Smart_error "Cannot read SMART data from (${DEVICE}), exit status: ${?}" "CRITICAL"
        continue
    fi

    #                                      Collapse multiple spaces,            attrs only
    SMART_ATTRS="$(smartctl -A "$DEVICE" | sed -e 's/^\s\+//' -e 's/\s\+/ /g' | grep '^[0-9]')"
    for ATTR in "${ZERO_ATTRS[@]}"; do
        if Check_zero "$SMART_ATTRS" "$ATTR"; then
            continue
        fi

        NORMAL_ATTR_VALUE="zero"
        ATTR_VALUE="$(grep "^${ATTR}\\b" <<<"$SMART_ATTRS" | cut -d " " -f 10)"

        # Skip on silenced attributes
        if [ "${#SILENCED_ATTRS[@]}" != 0 ]; then
            for SILENCED in "${SILENCED_ATTRS[@]}"; do
                # Change default value to silenced value
                test "${DEVICE}:${ATTR}" == "${SILENCED%=*}" && NORMAL_ATTR_VALUE="${SILENCED##*=}"
                # Skip error reporting on match
                test "${DEVICE}:${ATTR}=${ATTR_VALUE}" == "$SILENCED" && continue 2
            done
        fi

        ATTR_NAME="$(grep -o "^${ATTR} \\S\\+" <<<"$SMART_ATTRS")"
        Smart_error "Attribute ${ATTR_NAME} on ${DEVICE} changed from ${NORMAL_ATTR_VALUE} to ${ATTR_VALUE}" "WARNING"
    done
done
