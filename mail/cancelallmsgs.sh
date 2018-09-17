#!/bin/bash
#
# Cancel messages in Courier mail queue.
#
# VERSION       :1.2.2
# DATE          :2018-04-22
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-mta
# LOCATION      :/usr/local/sbin/cancelallmsgs.sh

# Usage
#
# You may provide a single ID to cancel only that message.
#
# Remarks
#
# User executing this script should have "ALL:ALL" sudo rights.
# editor /etc/sudoers
#     user	ALL=(ALL:ALL) ALL

# shellcheck disable=SC1091
MAILGROUP="$(source /etc/courier/esmtpd >/dev/null; echo "$MAILGROUP")"

mailq -sort -batch | head -n -1 \
    | cut -d ";" -f 2,4 \
    | grep -F "$1" \
    | while read -r ID_USER; do
        echo "${ID_USER%;*} ..."
        sudo -u "${ID_USER#*;}" -g "${MAILGROUP}" -- cancelmsg "${ID_USER%;*}" \
            || echo "Cancellation failed. (${ID_USER%;*})" 1>&2
    done

# @TODO strace -f -p `pidof cancelmsg`
