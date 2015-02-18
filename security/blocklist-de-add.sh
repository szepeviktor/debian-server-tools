#!/bin/bash
#
# Add blocklist.de's list for very abusive IP-s to iptables.
#
# VERSION       :0.1
# DATE          :2015-02-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/blocklist-de-add.sh

A5K_URL="http://lists.blocklist.de/lists/strongips.txt"
A5K_CHAIN="ATTACKER5K"

# check list integrity
A5K_MD5="$(wget -qO- "${A5K_URL}.md5")"
A5K_TMP="$(tempfile)"

wget -qO "$A5K_TMP" "$A5K_URL"
if ! [ -s "$A5K_TMP" ]; then
    echo "blocklist.de's strongips list update failed." >&2
    rm "$A5K_TMP"
    exit 1
fi

A5K_LIST_MD5="$(md5sum "$A5K_TMP")"
A5K_LIST_MD5="${A5K_LIST_MD5%% *}"
if [ "$A5K_LIST_MD5" != "$A5K_MD5" ]; then
    echo "blocklist.de's strongips list integrity failed." >&2
    rm "$A5K_TMP"
    exit 2
fi

# remove from INPUT for now
iptables -D INPUT -j "$A5K_CHAIN" &> /dev/null

# set up chain and rules
iptables -N "$A5K_CHAIN" &> /dev/null
iptables -F "$A5K_CHAIN"
while read A5K; do
    iptables -A "$A5K_CHAIN" -s "$A5K" -j DROP
done < "$A5K_TMP"
iptables -A "$A5K_CHAIN" -j RETURN

# add back to INPUT
iptables -C INPUT -j "$A5K_CHAIN" &> /dev/null || iptables -I INPUT -j "$A5K_CHAIN"

rm "$A5K_TMP"

tty --quiet && iptables -n -L "$A5K_CHAIN" | grep -w "^DROP" | wc -l
