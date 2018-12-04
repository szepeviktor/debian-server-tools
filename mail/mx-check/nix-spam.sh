#!/bin/bash

# Addresses
for _ in {1..20}; do
    wget -nv -O- "http://mailinator2.com/" \
        | grep -o '\b[a-zA-Z0-9][a-zA-Z0-9_.+-]*@[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z0-9.-]*[a-zA-Z][a-zA-Z]\b' \
        >>nix-spam-addr.list
    sleep 1
done

# Duplicates
uniq -d <nix-spam-addr.list

# MX records
cut -d "@" -f 2 nix-spam-addr.list \
    | xargs -I % host -t MX % localhost \
    | sed -n -e 's|^.* mail is handled by [0-9]\+ \(\S\+\.\)$|\1|p' \
    | sort -u \
    >nix-spam-mx.list
