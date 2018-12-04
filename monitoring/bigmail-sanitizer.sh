#!/bin/bash
#
# Remove BIG attachments.
#
# VERSION       :0.1.1
# DATE          :2016-02-12
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mpack s-nail
# DEPENDS       :/usr/local/bin/conv2047.pl
# LOCATION      :/usr/local/sbin/bigmail-sanitizer.sh
# CRON-DAILY    :/usr/local/sbin/bigmail-sanitizer.sh

MAIL_ROOT="/var/mail"
MAX_SIZE="4M"

set -e

Daily_warning() {
    local MPATH="$1"
    local MDIR
    local MSG
    local ATTACHMENT

    # Find BIG messages from the past day
    find "${MPATH}" -type f -mtime -1 -size +${MAX_SIZE} \
        | while read -r MSG; do
            MDIR="$(mktemp -d)"
            pushd "$MDIR" >/dev/null

            # Headers
            grep -m 1 "^From:" "$MSG" | conv2047.pl -d -c
            grep -m 1 "^To:" "$MSG" | conv2047.pl -d -c
            grep -m 1 "^Date:" "$MSG" | conv2047.pl -d -c

            # Attachments bigger than 100 kB
            munpack -f "$MSG" &>/dev/null
            find . -type f -size +100k \
                | while read -r ATTACHMENT; do
                    printf 'Attachment size: %s, file type:' "$(stat -c %s "$ATTACHMENT")"
                    file "$ATTACHMENT" | head -n 1 | cut -d ":" -f 2- | cut -c 1-120
                done
            echo

            popd >/dev/null
            rm -rf "$MDIR"
        done | s-nail -E -S "from=message size exceeded <root>" -s "${MPATH} on $(hostname -f)" root
}

find "$MAIL_ROOT" -mindepth 2 -maxdepth 2 -type d \
    | while read -r ACCOUNT; do
        Daily_warning "$ACCOUNT"
    done

# @TODO
# Weekly_move() -mtime +7 move messages to .Trash
# Fortnightly_move() -mtime +14 move messages from .Trash to /var/backup/big-message/...
