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

MAXSIZE="1M"
MAIL_ROOT="/var/mail"
STORAGE_BASE="/var/mail/attachments-5mb-plus"
TOPFOLDERS="20"

# detect folder sizes by email size
# generates .largefolders
find "$MAIL_ROOT" -type d -wholename "*/Maildir/*/cur" -exec du -sb \{\} \; \
    | sort -n | tail -n "$TOPFOLDERS" | cut -f2- | tee .largefolders

# separate
echo

# calculate total size of large emails
# generates .largemessages
while read FOLDER; do
    echo -n "${FOLDER}:"
    { find "$FOLDER" -type f -size "+${MAXSIZE}" -exec stat -c %s \{\} \; \
        | tr $'\n' '+'; echo 0; } | bc
done < .largefolders \
    | sort -t':' -k2 -n | tee .largemessages

# separate
echo

# copy and strip attachments
# generates error log: extract-attachments.log
echo -n > extract-attachments.log
while read MSG; do
    FOLDER="$(cut -d':' -f1 <<< "$MSG")"

    echo "*** ${FOLDER}"
    FOLDER_STORAGE="${FOLDER//[^a-z0-9]/_}"

    find "$FOLDER" -type f -size "+${MAXSIZE}" -exec \
        ./extract-one.sh \{\} "${STORAGE_BASE}/${FOLDER_STORAGE}" \; 2>> extract-attachments.log
done < .largemessages
