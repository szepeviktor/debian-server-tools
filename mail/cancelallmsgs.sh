#!/bin/bash
#
# /usr/local/sbin/cancelallmsgs.sh

# /etc/sudoers
#root	ALL=(ALL:ALL) ALL

MAIL_GROUP="daemon"

mailq -sort -batch | head -n -1 | cut -d';' -f 2,4 \
    | while read ID_USER; do
        sudo -u ${ID_USER#*;} -g "$MAIL_GROUP" -- cancelmsg ${ID_USER%;*}
    done

#TODO: strace cancelmsg
