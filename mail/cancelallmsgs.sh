#!/bin/bash
#
# Cancel messages in Courier mail queue.
#
# VERSION       :1.1.0
# DATE          :2015-10-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-mta
# LOCATION      :/usr/local/sbin/cancelallmsgs.sh

# Notice
#
# root user should have "ALL:ALL" sudo rights
# /etc/sudoers
#     root	ALL=(ALL:ALL) ALL

# Usage
#
# You may provide a single ID to cancel only that message.

MAIL_GROUP="daemon"

mailq -sort -batch | head -n -1 \
    | cut -d';' -f 2,4 \
    | grep "$1" \
    | while read ID_USER; do
        sudo -u ${ID_USER#*;} -g "$MAIL_GROUP" -- cancelmsg ${ID_USER%;*} \
            || echo "Cancellation failed. (${ID_USER%;*})" >&2
    done

# @TODO strace `pidof cancelmsg`
