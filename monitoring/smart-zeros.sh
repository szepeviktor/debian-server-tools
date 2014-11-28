#!/bin/bash
#
# Check specified S.M.A.R.T. attributes of all hard drives and SSD-s.
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
# Manual check: smartctl -A <DEVICE>
# Only /dev/sd* and /dev/hd* devices are detected.
#
# DEPENDS          :apt-get install -y heirloom-mailx smartmontools

ZERO_ATTRS=( 1 5 7 10 11 196 197 198 199 200 )
ALERT_ADDRESS="root"

Check_zero() {
    local SMART_ATTRS="$1"
    local ATTR="$2"
    # raw value is the 10th column
    local VALUE="$(grep "^${ATTR}\b" <<< "$SMART_ATTRS" | cut -d' ' -f10)"

    # not found
    [ -z "$VALUE" ] && return 2

    if [ "$VALUE" == 0 ]; then
        # OK: zero
        return 0
    else
        # non-zero
        return 1
    fi
}

Smart_error() {
    local MESSAGE="$1"
    local LEVEL="$2"

    if tty --quiet; then
        echo "[${LEVEL}] $MESSAGE" >&2
    else
        echo "$MESSAGE" | \
            mailx -s "[${LEVEL}] $(hostname --fqdn) S.M.A.R.T. error" -S from="smart-zeros <root>" "$ALERT_ADDRESS"
    fi
}

# check for smartmontools
which smartctl &> /dev/null || exit 99

# /dev/sd* and /dev/hd*
for DRIVE in $(grep -o "\b[hs]d[a-z]$" /proc/partitions); do
    DEVICE="/dev/${DRIVE}"

    if ! smartctl --info "$DEVICE" &> /dev/null; then
        Smart_error "Cannot read SMART data from (${DEVICE}), exit code: $?" "CRITICAL"
        continue
    fi

    #                                      collapse multiple spaces             attrs only
    SMART_ATTRS="$(smartctl -A "$DEVICE" | sed -e 's/^\s\+//' -e 's/\s\+/ /g' | grep '^[0-9]')"
    for ATTR in "${ZERO_ATTRS[@]}"; do
        if ! Check_zero "$SMART_ATTRS" "$ATTR"; then
            Smart_error "Attribute $(grep -o "^${ATTR} \S\+" <<< "$SMART_ATTRS") changed from zero on (${DEVICE})" "WARNING"
            continue 2
        fi
    done
done
