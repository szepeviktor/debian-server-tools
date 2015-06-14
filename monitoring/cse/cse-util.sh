#!/bin/bash
#
# Set up can-send-email.
#
# VERSION       :1.1.0
# DATE          :2015-06-13
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+

# Install
./install.sh mail/cse/can-send-email.sh

# Create database
can-send-email.sh --init || exit 1

# Add Courier alias
echo 'editor /etc/courier/aliases/system'
echo 'cse@worker.szepe.net:  |/usr/local/sbin/can-send-email.sh'
echo 'courier-restart.sh'
