#!/bin/bash

WAN_IF="eth0"
WAN_IP="$(ip addr show dev "${WAN_IF}"|grep -o -m 1 "inet [0-9\.]*"|cut -d' ' -f 2)"

cd /etc/apache2

source envvars

echo "Incorrect:"
apache2 -S | grep -o "namevhost [^ ]*\|alias [^ ]*" | cut -d' ' -f2 \
    | while read D; do
        # don't show correct records and aliases
        host -t A "$D" | grep -v " has address ${WAN_IP//./\\.}$\| is an alias for "
    done

echo -e "\nAliases:"
apache2 -S | grep -o "namevhost [^ ]*\|alias [^ ]*" | cut -d' ' -f2 \
    | while read D; do
        # show only aliases
        host -t A "$D" | grep " is an alias for "
    done
