#!/bin/bash
#
# Show incorrect Apache domain names.
#
#DEPENDS        :apt-get install apache2 bind9-host

WAN_IF="eth0"
WAN_IP="$(ip addr show dev ${WAN_IF}|sed -n -e 's_^\s*inet \([0-9\.]\+\)\b.*$_\1_' -e 's_\._\\._gp')"

echo "Apache domains with possible failure:"
apache2ctl -S | sed -n 's_^.*\(namevhost\|alias\) \(\S\+\).*$_\2_p' \
    | while read DOMAIN; do
        # Don't show correct A records and CNAME records
        host -t A "$DOMAIN" | grep -v " has address ${WAN_IP}$\| is an alias for "
        # Show only CNAME records
        host -t A "$DOMAIN" | grep " is an alias for "
    done
