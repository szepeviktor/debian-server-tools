#!/bin/bash
#
# Archive database dumps.
#

#TODO: sqlite3 in ~/glacier/
# site ID, swift container, export-one-db URL, secret key, user agent
DBS=(
# Fill in website details
)
WORKDIR="/home/bck/database/workdir"
PRIVKEYS="/home/bck/database/privkeys"
HUBIC="/usr/local/bin/hubic.py"
EXP_O_DECRYPT="/usr/local/bin/exp-o-decrypt.php"
ENCRYPT_PASS_FILE="/home/bck/database/.enc-pass"
TODAY="$(date --rfc-3339=date)"

# Decryption
#
#hubic.py --swift -- download <CONTAINER> <PATH/FILE>
#zpaq x "<PATH/FILE>.zpaq" -key "$(cat "$ENCRYPT_PASS_FILE")"

E() {
    local ALL="$1"
    local FIELD="$2"
    cut -d "," -f "$FIELD" <<< "$ALL"
}

# Backup only to secure directoy
[ "$(stat --format=%a .)" == 700 ] || exit 1

# Interrupted backup
[ -z "$(ls -A "$WORKDIR")" ] || exit 2

cd "$WORKDIR" || exit 3

# Check object storage access
"$HUBIC" --swift -- stat > /dev/null || exit 4


for DB in ${DBS[*]}; do
    ID="$(E "$DB" 1)"
    CONTAINER="$(E "$DB" 2)"
    URL="$(E "$DB" 3)"
    SECRET="$(E "$DB" 4)"
    UA="$(E "$DB" 5)"

    tty --quiet && echo "${ID} ..."

    # Export database dump
    if ! wget -q -S --content-disposition --user-agent="$UA" \
        --header="X-Secret-Key: ${SECRET}" -O "${ID}.sql.gz.enc" "$URL" 2> "${ID}.headers"; then
        echo "Error during database backup of ${ID}." >&2
        continue
    fi

    # Check dump and header files
    if ! [ -s "${ID}.headers" ] || ! [ -s "${ID}.sql.gz.enc" ]; then
        echo "Backup failed ${ID}." >&2
        continue
    fi

    # Get password
    PASSWORD="$(grep -m1 "^  X-Password:" "${ID}.headers"|cut -d" " -f4-)"
    if [ -z "$PASSWORD" ]; then
        echo "No password found in response ${ID}." >&2
        continue
    fi

    # Decrypt dump
    if ! OPENSSL_DECRYPT="$("$EXP_O_DECRYPT" "$PASSWORD" "$(cat "${PRIVKEYS}/${ID}.iv")" "${PRIVKEYS}/${ID}.key")"; then #"
        echo "Password retrieval failed ${ID}." >&2
        continue
    fi
    if ! ${OPENSSL_DECRYPT} ${ID}.sql.gz.enc | gzip -d > "${ID}.sql"; then
        echo "Dump decryption failed ${ID}." >&2
        continue
    fi
    rm "${ID}.sql.gz.enc"

    # Archive (compress and encrypt)
    "$HUBIC" --swift -- -q download --output "${ID}-00000.zpaq" "$CONTAINER" "${ID}/${ID}-00000.zpaq" 2> /dev/null
    if ! zpaq a "${ID}-?????.zpaq" "${ID}.sql" "${ID}.headers" -method 5 -key "$(cat "$ENCRYPT_PASS_FILE")" &> /dev/null; then
        echo "Archiving failed ${ID}." >&2
        continue
    fi
    rm "${ID}.sql" "${ID}.headers"

    # Upload archive
    for ZPAQ in "$ID"-?????.zpaq; do
        if ! "$HUBIC" --swift -- -q upload --object-name "${ID}/${ZPAQ}" "$CONTAINER" "$ZPAQ"; then
            echo "Archive upload failed ${ID}/${ZPAQ}." >&2
        fi
        rm "$ZPAQ"
    done
done

# swift full?
[ $("$HUBIC" --swift -- stat | grep -m1 "Bytes:" | cut -d":" -f2) -gt 1000000000 ] && echo "swift FULL." >&2

exit 0
