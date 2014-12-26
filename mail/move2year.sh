#!/bin/bash
#
# Move old messages to a yearly folder.
#
# VERSION       :0.1
# DATE          :2014-10-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+


# Create maildir folder
# maildirmake -f archive.inbox-2014 /var/mail/MAILDIR
# maildirmake -f archive.sent-2014 /var/mail/MAILDIR

YEAR="$1"
FROM_FOLDER="$2"
TO_FOLDER="$3"

[ -z "$YEAR" ] && exit 1
[ -d "$FROM_FOLDER" ] || exit 2
[ -d "$TO_FOLDER" ] || exit 3
[ "$(basename "$FROM_FOLDER")" == "cur" ] || exit 4
[ "$(basename "$TO_FOLDER")" == "cur" ] || exit 5

YEAR_START="$(date -d"${YEAR}-01-01 00:00:00" "+%s")"
YEAR_END="$(date -d"${YEAR}-12-31 23:59:59" "+%s")"

find "$FROM_FOLDER" -type f \
    | while read FILE; do
        # determine date from timestamp in filename
        DATE_STAMP="$(basename "${FILE}")"
        DATE_STAMP="${DATE_STAMP:0:10}"
        # validity
        if [ -z "$DATE_STAMP" ] || ! [ -z "${DATE_STAMP//[0-9]/}" ]; then
            echo "Couldn't get timestamp from file name: ${FILE}" >&2
            continue
        fi

        # in current year
        if [ "$DATE_STAMP" -ge "$YEAR_START" ] && [ "$DATE_STAMP" -le "$YEAR_END" ]; then
            echo -n "$(date -d"@${DATE_STAMP}" -R) "
            mv -v "$FILE" "$TO_FOLDER"
        fi
    done

#TODO chown, chmod
