#!/bin/bash
#
# Restore a database backup made with bck-dbz.sh
#
# VERSION       :1.0.1
# DATE          :2015-06-12
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :https://github.com/puzzle1536/hubic-wrapper-to-swift
# DEPENDS       :apt-get install zpaq
# LOCATION      :/home/bck/database/restore-dbz.sh
# OWNER         :bck:bck
# PERMISSION    :755

# site ID,swift container,export-one-db URL,secret key,user agent
declare DB=""
HUBIC="/usr/local/bin/hubic.py --config=/home/bck/database/.hubic.cfg"
ENCRYPT_PASS_FILE="/home/bck/database/.enc-pass"

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
    local -i TRIES="2"
    local -i TRY="0"

    while [ "$((TRY++))" -lt "$TRIES" ]; do
        # Empty error message
        echo -n "" > "$SWIFT_STDERR"

        # Be verbose on console and on "swift stat"
        ${HUBIC} --swift -- -v "$@" 2> "$SWIFT_STDERR"
        RET="$?"

        # OK
        if [ "$RET" -eq 0 ] && ! grep -qv "^[A-Z_]\+=\S\+$" "$SWIFT_STDERR"; then
            break
        fi

        echo -n "Swift ERROR ${RET} " 1>&2
        cat "$SWIFT_STDERR" >&2
        RET="255"
        # Wait for object storage
        sleep 60
    done

    return "$RET"
}

# Check object storage access
if ! Swift stat > /dev/null; then
    exit 4
fi

ID="$(E "$DB" 1)"
CONTAINER="$(E "$DB" 2)"
URL="$(E "$DB" 3)"
SECRET="$(E "$DB" 4)"
UA="$(E "$DB" 5)"

echo "Restoring ${ID} ..."

# Download
if ! Swift download --prefix "${ID}/${ID}-" "$CONTAINER"; then
    exit 10
fi

# List all versions
zpaq l "${ID}/${ID}-?????.zpaq" -key "$(cat "$ENCRYPT_PASS_FILE")" -all

# Restore latest version
if ! zpaq x "${ID}/${ID}-?????.zpaq" "${ID}.sql" -key "$(cat "$ENCRYPT_PASS_FILE")"; then
    echo "Restore failed ${ID}." 1>&2
    exit 11
fi
