#!/bin/bash
#
# Set up can-send-email.
#
# VERSION       :1.1.1
# DATE          :2015-06-20
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+

# Install
[ "$(dirname "$0")" == "cse" ] && cd ../..
./install.sh mail/cse/can-send-email.sh

# Create database
can-send-email.sh --init || exit 1

# Add Courier alias
echo 'editor /etc/courier/aliases/system'
echo '    cse@worker.szepe.net:  |/usr/local/sbin/can-send-email.sh'
echo '    daemon:                postmaster'
echo 'courier-restart.sh'
