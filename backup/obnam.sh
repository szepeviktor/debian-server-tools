#!/bin/bash
#
# Very simple obnam script without LVM snapshot
#

declare -a VOLUMES=( boot:/boot/ homes:/home/ kozos:/storage/ )
MOUNT_POINT="/media/backup"
#FIXME MOUNT_POINT_UUID=""
OBNAM_REPO="${MOUNT_POINT}/.obnam"
OBNAM_KEEP_POLICY="14d,3m,1y"
OBNAM_EXCLUDES="--exclude=/var/run --exclude=/var/spool --exclude=/var/backups --exclude=/var/cache/apt --exclude=/var/spool/squid"

OBNAM_DEFAULTS="--one-file-system --compress-with=deflate --log=syslog --log-level=info"
OBNAM_DEFAULTS+=" --keep=${OBNAM_KEEP_POLICY} --repository=${OBNAM_REPO} ${OBNAM_EXCLUDES}"

# quiet on cron
tty --quiet || OBNAM_DEFAULTS="--quiet ${OBNAM_DEFAULTS}"

# umount on every exit
trap "umount "$MOUNT_POINT" &> /dev/null" EXIT

error() {
    echo "ERROR: $*" >&2
    ##umount "$MOUNT_POINT" &> /dev/null
    exit $1
}


# mount backup disk: odd and even weeks
if ! mount -U "92fa7957-9b77-4897-aa36-3a952b2e9f25" "$MOUNT_POINT" &> /dev/null \
    && ! mount -U "ebd601d9-5182-48cb-a56b-ea88bcd9c177" "$MOUNT_POINT" &> /dev/null; then
    error 2 "Failed to mount backup disk"
fi

# loop through volumes
for VOLUME in ${VOLUMES[*]}; do
    nice /usr/bin/python /usr/bin/obnam ${OBNAM_DEFAULTS} \
        --client-name=${VOLUME%:*} backup ${VOLUME#*:} || error 1 "obname failure in ${VOLUME#*:}, exit code: $?, SEE syslog"
done

##umount "$MOUNT_POINT" || error 3 "Cannot umount (${MOUNT_POINT})"

exit 0

# cd /media/backup/.obnam && for C in fsroot boot homes kozos;do echo -- $C;obnam --client=$C generations;done|most
