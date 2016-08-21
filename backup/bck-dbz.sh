#!/bin/bash
#
# Backup a remote database over FTP.
#
# VERSION       :1.4.5
# DATE          :2015-08-15
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :https://github.com/puzzle1536/hubic-wrapper-to-swift
# DEPENDS       :apt-get install openssl zpaq
# LOCATION      :/home/bck/database/bck-dbz.sh
# OWNER         :bck:bck
# PERMISSION    :755
# CRON.D        :03 3	* * *	bck	/home/bck/database/bck-dbz.sh
# CONFIG        :/home/bck/database/.dbftp

# List files
#
#      hubic.py --swift -- list CONTAINER --long

source "$(dirname "$0")/.dbftp"
# site ID,swift container,export-one-db URL,secret key,user agent
#declare -a DBS=(
#)
#WORKDIR="/home/bck/database/workdir"
#PRIVKEYS="/home/bck/database/privkeys"
#HUBIC="/usr/local/bin/hubic.py --config=/home/bck/database/.hubic.cfg"
#EXP_O_DECRYPT="/usr/local/bin/exp-o-decrypt.php"
#ENCRYPT_PASS_FILE="/home/bck/database/.enc-pass"

# Local swift command
PATH="${PATH}:/usr/local/bin"

SWIFT_STDERR="$(mktemp)"
trap "rm -f '$SWIFT_STDERR' &> /dev/null" EXIT HUP INT QUIT PIPE TERM

# Get n-th field of a comma separated list
E() {
    local ALL="$1"
    local FIELD="$2"
    cut -d "," -f "$FIELD" <<< "$ALL"
}

# Communicate with object storage
Swift() {
    local -i RET="-1"
    local -i TRIES="3"
    local -i TRY="0"

    while [ "$((TRY++))" -lt "$TRIES" ]; do
        # Empty error message
        echo -n "" > "$SWIFT_STDERR"

        # Be verbose on console and on `Swift stat`
        if tty --quiet || [ "stat" == "$1" ]; then
            ${HUBIC} -v --swift -- -v "$@" 2> "$SWIFT_STDERR"
            RET="$?"
        else
            ${HUBIC} --swift -- -q "$@" > /dev/null 2> "$SWIFT_STDERR"
            RET="$?"
        fi

        # OK
        if [ "$RET" -eq 0 ] && ! grep -qvx "[A-Z_]\+=\S\+" "$SWIFT_STDERR"; then
            break
        fi

        echo -n "Swift ERROR ${RET} during ($*), error message: " 1>&2
        cat "$SWIFT_STDERR" 1>&2
        RET="255"

        # Wait for object storage
        sleep 60
    done

    return "$RET"
}

# Backup only to secure directory
[ "$(stat --format=%a $(dirname "$WORKDIR"))" == 700 ] || exit 1

# Interrupted backup
[ -z "$(ls -A "$WORKDIR")" ] || exit 2

cd "$WORKDIR" || exit 3

# Check object storage access
if ! Swift stat > /dev/null; then
    echo "Object storage access failure." 1>&2
    exit 4
fi

for DB in "${DBS[@]}"; do
    ID="$(E "$DB" 1)"
    CONTAINER="$(E "$DB" 2)"
    URL="$(E "$DB" 3)"
    SECRET="$(E "$DB" 4)"
    UA="$(E "$DB" 5)"

    if tty --quiet; then
        echo "${ID} ..."
    else
        logger -t "bck-dbz[$$]" "Archiving ${ID}"
    fi

    # Download database dump
    if ! wget -q -S --user-agent="$UA" \
        --header="X-Secret-Key: ${SECRET}" -O "${ID}.sql.gz.enc" "$URL" 2> "${ID}.headers"; then
        echo "Error during database backup of ${ID}." 1>&2
        continue
    fi

    # Check dump and header files
    if ! [ -s "${ID}.headers" ] || ! [ -s "${ID}.sql.gz.enc" ]; then
        echo "Backup failed ${ID}." 1>&2
        continue
    fi

    # Get password
    PASSWORD="$(grep -m1 "^  X-Password:" "${ID}.headers"|cut -d" " -f4-)"
    if [ -z "$PASSWORD" ]; then
        echo "No password found in response ${ID}." 1>&2
        continue
    fi

    # Decrypt dump
    if ! OPENSSL_DECRYPT="$("$EXP_O_DECRYPT" "$PASSWORD" "$(cat "${PRIVKEYS}/${ID}.iv")" "${PRIVKEYS}/${ID}.key")"; then #"
        echo "Password retrieval failed ${ID}." 1>&2
        continue
    fi
    if ! ${OPENSSL_DECRYPT} ${ID}.sql.gz.enc | gzip -d > "${ID}.sql"; then
        echo "Dump decryption failed ${ID}." 1>&2
        continue
    fi
    rm "${ID}.sql.gz.enc"

    # Download archive index
    if ! Swift download --output "${ID}-00000.zpaq" "$CONTAINER" "${ID}/${ID}-00000.zpaq" \
        || ! [ -s "${ID}-00000.zpaq" ]; then
        echo "Archive index download failed ${ID}." 1>&2
        continue
    fi

    # Archive (compress and encrypt)
    if ! zpaq add "${ID}-?????.zpaq" "${ID}.sql" "${ID}.headers" -method 5 -key "$(cat "$ENCRYPT_PASS_FILE")" &> /dev/null; then
        echo "Archiving failed ${ID}." 1>&2
        continue
    fi
    rm "${ID}.sql" "${ID}.headers"

    # Upload archive parts
    for ZPAQ in "$ID"-*.zpaq; do
        if ! Swift upload --object-name "${ID}/${ZPAQ}" "$CONTAINER" "$ZPAQ"; then
            echo "Archive upload failed ${ID}/${ZPAQ}, may cause inconsistency." 1>&2
            continue
        fi
        rm "$ZPAQ"
    done
done

# Leftover files
if ! [ -z "$(ls -A "$WORKDIR")" ]; then
    echo "There was an error, files are left in working directory." 1>&2
fi

# Check object storage usage
declare -i GBYTE_LIMIT="20"
declare -i BYTE_LIMIT="$(( GBYTE_LIMIT * 1000 * 1000 * 1000 ))"
SWIFT_BYTES="$(Swift stat)"
SWIFT_BYTES="$(echo "$SWIFT_BYTES" | grep -m 1 "Bytes:" | cut -d ":" -f 2)"
if [ -n "$SWIFT_BYTES" ] && [ ${SWIFT_BYTES} -gt "$BYTE_LIMIT" ]; then
    echo "Swift usage greater than ${GBYTE_LIMIT} GiB." 1>&2
fi

#wget -q -t 3 -O- "https://hchk.io/${UUID}" | grep -Fx "OK"

exit 0
