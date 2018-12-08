#!/bin/bash
#
# List incorrect Apache domain names.
#
# VERSION       :0.2.0
# DATE          :2015-08-26
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install apache2 bind9-host
# LOCATION      :/usr/local/sbin/apache-resolve-hostnames.sh

# Interface for Apache
WAN_IF="eth0"

WAN_IP="$(ip addr show dev "$WAN_IF" | sed -n -e 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/' -e 's/\./\\./gp')"

echo "Apache domains with possible failure:"

apache2ctl -S | sed -n -e 's/^.*\(namevhost\|alias\) \(\S\+\).*$/\2/p' \
    | grep -F -v -x 'localhost' \
    | while read -r DOMAIN; do
        # Don't show correct A records nor CNAME records
        host -t A "$DOMAIN" | grep -v " has address ${WAN_IP//./\\.}\$\\| is an alias for "
        # Show only CNAME records
        host -t A "$DOMAIN" | grep ' is an alias for '
    done
