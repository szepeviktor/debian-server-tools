#!/bin/sh
#
# Fix duplicate IP problem.
#
# VERSION       :0.2.0
# ORIGIN        :Aruba Debian image /etc/rc.local Arp Cache Broadcast Request
# DEPENDS       :apt-get install arping
# LOCATION      :/etc/network/if-up.d/00aruba-arping

# Non if-up.d method
#
#     #   Exclude loopback interface
#     #   Output "IPv4 address:interface name"
#     IP_IFS="$(ip addr show \
#         | grep -Fv "inet 127." \
#         | sed -n -e 's|^\s\+inet \([0-9.]\+\)/[0-9]\+ .\+ \(\S\+\)$|\1:\2|p')"
#     for IP_IF in ${IP_IFS}; do
#         arping -q -A -c 2 -i "${IP_IF##*:}" "${IP_IF%%:*}" > /dev/null 2>&1
#     done
#     exit 0

set -e

command -v arping > /dev/null

# shellcheck disable=SC1091
. /lib/lsb/init-functions

if [ -z "$IF_ADDRESS" ] || [ "$ADDRFAM" != inet ]; then
    exit 0
fi

log_action_begin_msg "Fixing duplicate IP problem on restart: ${IF_ADDRESS}"

arping -q -A -c 2 -i "$IFACE" "$IF_ADDRESS" || true

log_action_end_msg 0 "Done."
