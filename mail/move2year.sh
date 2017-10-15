#!/bin/bash
#
# Move old messages to a yearly folder.
#
# VERSION       :0.2.0
# DATE          :2017-10-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/move2year.sh

# Create maildir folders for last year
#
#     sudo -u virtual -- maildirmake -f archive.inbox-2014 /var/mail/user/Maildir
#     sudo -u virtual -- maildirmake -f archive.sent-2014 /var/mail/user/Maildir
#
# Usage example
#
#     move2year.sh 2016 /var/mail/user/Maildir/cur /var/mail/user/Maildir/archive.inbox-2016/cur
#     move2year.sh 2016 /var/mail/user/Maildir/.Sent/cur /var/mail/user/Maildir/archive.sent-2016/cur
#
# Inbox message count
#
#     find /var/mail -mindepth 2 -maxdepth 2 -type d \
#         | xargs -I{} bash -c "echo -n {}:;ls {}/Maildir/cur|wc -l"
#
# Last five messages in the inbox
#
#     find /var/mail -mindepth 2 -maxdepth 2 -type d \
#         | xargs -I % bash -c "echo '%:'; ls -lt --full-time '%/Maildir/cur' | tail -n 5 | cut -c 1-100"
#
# This year's messages in the inbox
#
#     find /var/mail -mindepth 2 -maxdepth 2 -type d \
#         | xargs -I % bash -c "echo -n '%:'; find '%/Maildir/cur' -type f -mtime -365 | wc -l"
#
# 1 year old messages in the inbox
#
#     find /var/mail -mindepth 2 -maxdepth 2 -type d \
#         | xargs -I % bash -c "echo -n '%:'; find '%/Maildir/cur' -type f -mtime -730 -mtime +365 | wc -l"
#
# 2+ years old messages in the inbox
#
#     find /var/mail -mindepth 2 -maxdepth 2 -type d \
#         | xargs -I % bash -c "echo -n '%:'; find '%/Maildir/cur' -type f -mtime +730 | wc -l"

YEAR="$1"
FROM_FOLDER="$2"
TO_FOLDER="$3"

[ -z "$YEAR" ] && exit 1
[ -d "$FROM_FOLDER" ] || exit 2
[ -d "$TO_FOLDER" ] || exit 3
[ "$(basename "$FROM_FOLDER")" == "cur" ] || exit 4
[ "$(basename "$TO_FOLDER")" == "cur" ] || exit 5
[ -d "${FROM_FOLDER}/../tmp" ] || exit 6
[ -d "${TO_FOLDER}/../tmp" ] || exit 7

YEAR_START="$(date -d "${YEAR}-01-01 00:00:00" "+%s")"
YEAR_END="$(date -d "${YEAR}-12-31 23:59:59" "+%s")"

find "$FROM_FOLDER" -type f \
    | while read -r MESSAGE; do
        # Determine date from timestamp in file name
        DATE_STAMP="$(basename "$MESSAGE")"
        DATE_STAMP="${DATE_STAMP:0:10}"

        # Validity
        if [ -z "$DATE_STAMP" ] || [ -n "${DATE_STAMP//[0-9]/}" ]; then
            echo "Couldn't get timestamp from file name: ${MESSAGE}" 1>&2
            continue
        fi

        # Move messages of the specified year
        if [ "$DATE_STAMP" -ge "$YEAR_START" ] && [ "$DATE_STAMP" -le "$YEAR_END" ]; then
            echo -n "$(date -R -d "@${DATE_STAMP}") "
            # mv command retains owner and permissions
            mv -v "$MESSAGE" "$TO_FOLDER"
        fi
    done
