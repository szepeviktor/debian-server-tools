#!/bin/bash
#
# Very simple obnam script (without LVM or BTRFS snapshot)
#

declare -a VOLUMES=( fsroot:/ boot:/boot/ homes:/home/ shared:/storage/ )
MOUNT_POINT="/media/backup"
declare -a DISK_UUID=( aaaaaaaa-9999-9999-aaaa-999999999999 bbbbbbbb-1111-1111-bbbb-111111111111 )
MOUNT_SUCCESS="0"
OBNAM_REPO="${MOUNT_POINT}/.obnam"
OBNAM_KEEP_POLICY="14d,5m,2y"
OBNAM_EXCLUDES="--exclude=/var/run --exclude=/var/spool --exclude=/var/backups --exclude=/var/cache/apt --exclude=/var/spool/squid"

OBNAM_DEFAULTS="--one-file-system --compress-with=deflate --log=syslog --log-level=info"
OBNAM_DEFAULTS+=" --repository=${OBNAM_REPO} ${OBNAM_EXCLUDES}"

# Quiet on cron
tty --quiet || OBNAM_DEFAULTS+=" --quiet"

# Umount on every exit
trap "umount "$MOUNT_POINT" &> /dev/null" EXIT

error() {
    echo "ERROR: $*" >&2
    exit $1
}

# Mount a backup disk
for DISK in ${DISK_UUID[*]}; do
    if mount -U "$DISK" "$MOUNT_POINT" &> /dev/null; then
        MOUNT_SUCCESS="1"
        break
    fi
done
if [ "$MOUNT_SUCCESS" == 0 ]; then
    error 3 "Failed to mount backup disk"
fi

# 7:1 probability
DO_FORGET="$((RANDOM / 4682))"

# Loop through volumes
for VOLUME in ${VOLUMES[*]}; do
    nice /usr/bin/obnam ${OBNAM_DEFAULTS} \
        --client-name=${VOLUME%:*} backup ${VOLUME#*:} \
        || error 1 "obnam failure in ${VOLUME#*:}, exit code: $?, SEE syslog"
    if [ "$DO_FORGET" == 0 ]; then
        nice /usr/bin/obnam ${OBNAM_DEFAULTS} \
            --client-name=${VOLUME%:*} --keep=${OBNAM_KEEP_POLICY} forget \
            || error 2 "obnam forget failure in ${VOLUME%:*}, exit code: $?, SEE syslog"
    fi
done

exit 0

# cd /media/backup/.obnam && for C in fsroot boot homes kozos;do echo -- $C;obnam --client=$C generations;done|most
