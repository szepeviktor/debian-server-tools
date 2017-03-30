#!/bin/bash
#
# Cancel messages in Courier mail queue.
#
# VERSION       :1.1.2
# DATE          :2015-10-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-mta
# LOCATION      :/usr/local/sbin/cancelallmsgs.sh

# Usage
#
# You may provide a single ID to cancel only that message.

# Remarks
#
# "root" user should have "ALL:ALL" sudo rights.
# editor /etc/sudoers
#     root	ALL=(ALL:ALL) ALL

MAIL_GROUP="daemon"

mailq -sort -batch | head -n -1 \
    | cut -d ";" -f 2,4 \
    | grep -F "$1" \
    | while read -r ID_USER; do
        # shellcheck disable=SC2086
        sudo -u ${ID_USER#*;} -g ${MAIL_GROUP} -- cancelmsg "${ID_USER%;*}" \
            || echo "Cancellation failed. (${ID_USER%;*})" 1>&2
    done

# @TODO strace -f -p `pidof cancelmsg`
