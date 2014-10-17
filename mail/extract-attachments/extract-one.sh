#!/bin/bash
#
# Create unique storage folder for one email and call save_all_attachments.
#
# VERSION       :0.1
# DATE          :2014-10-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+

EMAIL="$1"
FOLDER_STORAGE="$2"

# title
echo -n "--- "
basename "$EMAIL"

# parse date for storage folder name
EMAIL_DATE="$(grep -m 1 '^Date: [a-zA-Z0-9, +)(\:-]\+$' "$EMAIL")"
EMAIL_DATE="${EMAIL_DATE#Date: }"
if [ -z "$EMAIL_DATE" ]; then
    echo "No date header in email: ${EMAIL}" >&2
    exit
fi

# set directory to store attachments
STORAGE="${FOLDER_STORAGE}/$(LC_ALL=C date -d "$EMAIL_DATE" "+%Y%m%d-%H%M%S")"
if [ $? != 0 ]; then
    echo "Invalid date header (${EMAIL_DATE}) in email: ${EMAIL}" >&2
    exit
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
