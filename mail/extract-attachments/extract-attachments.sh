#!/bin/bash
#
# Find largest emails, save&strip attachments.
#
# VERSION       :0.1
# DATE          :2014-10-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :./save_all_attachments.py

MAXSIZE="1M"
MAIL_ROOT="/var/mail"
STORAGE_BASE="/var/mail/attachments-5mb-plus"
TOPFOLDERS="20"

[ -x ./save_all_attachments.py ] && exit 99

Extract_one() {
    local EMAIL="$1"
    local FOLDER_STORAGE="$2"
    local -i EXISTING

    # title
    echo -n "--- "
    basename "$EMAIL"

    # parse date for storage folder name
    EMAIL_DATE="$(grep -m 1 '^Date: [a-zA-Z0-9, +)(\:-]\+$' "$EMAIL")"
    EMAIL_DATE="${EMAIL_DATE#Date: }"
    if [ -z "$EMAIL_DATE" ]; then
        echo "No date header in email: ${EMAIL}" 1>&2
        return
    fi

    # set directory to store attachments
    if ! STORAGE="${FOLDER_STORAGE}/$(LC_ALL=C date -d "$EMAIL_DATE" "+%Y%m%d-%H%M%S")"; then
        echo "Invalid date header (${EMAIL_DATE}) in email: ${EMAIL}" 1>&2
        return
    fi

    # add a number if already exists
    if [ -d "$STORAGE" ]; then
        EXISTING="$(find "$(dirname "$STORAGE")" -maxdepth 1 -type d -name "${STORAGE}*" | wc -l)" #"
        STORAGE+=".${EXISTING}"
    fi
    mkdir -p "$STORAGE"

    # remember recipient, from and file path and strip&save attachments
    if ! ./save_all_attachments.py --verbose --delete --dir "$STORAGE" "$EMAIL"; then
        echo "extract error ($?): ${STORAGE} / ${EMAIL}" 1>&2
    fi

    # if only _email.txt is generated
    if [ "$(find "$STORAGE" -type f | wc -l)" == 1 ]; then
        rm "{$STORAGE}/_email.txt"
        rmdir "$STORAGE"
    fi

    # separator
    echo
}

set +e

# detect folder sizes by email size
# generates .largefolders
find "$MAIL_ROOT" -type d -wholename "*/Maildir/*/cur" -exec du -sb "{}" ";" \
    | sort -n | tail -n "$TOPFOLDERS" | cut -f 2- | tee .largefolders

# separator
echo

# calculate total size of large emails
# generates .largemessages
while read -r FOLDER; do
    echo -n "${FOLDER}:"
    { find "$FOLDER" -type f -size "+${MAXSIZE}" -exec stat -c %s "{}" ";" \
        | tr $'\n' "+"; echo "0"; } | bc
done < .largefolders \
    | sort -t ":" -k 2 -n | tee .largemessages

# separator
echo

# copy and strip attachments
# generates error log: extract-attachments.log
echo -n > extract-attachments.log
while read -r MSG; do
    FOLDER="$(cut -d ":" -f 1 <<< "$MSG")"

    echo "*** ${FOLDER}"
    FOLDER_STORAGE="${FOLDER//[^a-z0-9]/_}"

    find "$FOLDER" -type f -size "+${MAXSIZE}" \
        | while read -r EMAIL_FILE; do
            Extract_one "$EMAIL_FILE" "${STORAGE_BASE}/${FOLDER_STORAGE}" 2>> extract-attachments.log
        done
done < .largemessages
