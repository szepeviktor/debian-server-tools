#!/bin/bash
#
# Find largest emails, save&strip attachments.
# save_all_attachments.py needs to be in the current dir.
#
# VERSION       :0.1
# DATE          :2014-10-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+

MAXSIZE="1M"
MAIL_ROOT="/var/mail"
STORAGE_BASE="/var/mail/attachments-5mb-plus"
TOPFOLDERS="20"

Extract_one() {
    local EMAIL="$1"
    local FOLDER_STORAGE="$2"

    # title
    echo -n "--- "
    basename "$EMAIL"

    # parse date for storage folder name
    EMAIL_DATE="$(grep -m 1 '^Date: [a-zA-Z0-9, +)(\:-]\+$' "$EMAIL")"
    EMAIL_DATE="${EMAIL_DATE#Date: }"
    if [ -z "$EMAIL_DATE" ]; then
        echo "No date header in email: ${EMAIL}" >&2
        return
    fi

    # set directory to store attachments
    STORAGE="${FOLDER_STORAGE}/$(LC_ALL=C date -d "$EMAIL_DATE" "+%Y%m%d-%H%M%S")"
    if [ $? != 0 ]; then
        echo "Invalid date header (${EMAIL_DATE}) in email: ${EMAIL}" >&2
        return
    fi

    # if already exists add a number
    if [ -d "$STORAGE" ]; then
        SAME="$(ls -d "$STORAGE"* | wc -l)"
        STORAGE+=".$(( SAME ))"
    fi
    mkdir -p "$STORAGE"

    # remember recipient, from and file path and strip&save attachments
    if ! ./save_all_attachments.py --verbose --delete --dir "$STORAGE" "$EMAIL"; then
        echo "extract error ($?): ${STORAGE} / ${EMAIL}" >&2
    fi

    # if only _email.txt is generated
    if [ "$(ls "$STORAGE" | wc -l)" == "1" ]; then
        rm "{$STORAGE}/_email.txt"
        rmdir "$STORAGE"
    fi

    # separator
    echo
}

# detect folder sizes by email size
# generates .largefolders
find "$MAIL_ROOT" -type d -wholename "*/Maildir/*/cur" -exec du -sb \{\} \; \
    | sort -n | tail -n "$TOPFOLDERS" | cut -f2- | tee .largefolders

# separator
echo

# calculate total size of large emails
# generates .largemessages
while read FOLDER; do
    echo -n "${FOLDER}:"
    { find "$FOLDER" -type f -size "+${MAXSIZE}" -exec stat -c %s \{\} \; \
        | tr $'\n' '+'; echo 0; } | bc
done < .largefolders \
    | sort -t':' -k2 -n | tee .largemessages

# separator
echo

# copy and strip attachments
# generates error log: extract-attachments.log
echo -n > extract-attachments.log
while read MSG; do
    FOLDER="$(cut -d':' -f1 <<< "$MSG")"

    echo "*** ${FOLDER}"
    FOLDER_STORAGE="${FOLDER//[^a-z0-9]/_}"

    # extract-one.sh needs to be a different file, we are in a pipe already
    find "$FOLDER" -type f -size "+${MAXSIZE}" \
        | while read EMAIL_FILE; do
            Extract_one "$EMAIL_FILE" "${STORAGE_BASE}/${FOLDER_STORAGE}" 2>> extract-attachments.log
        done
done < .largemessages
