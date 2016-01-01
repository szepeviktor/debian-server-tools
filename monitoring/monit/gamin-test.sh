#!/bin/bash
#
# Connect to gamin server for session test.
#
# VERSION       :1.1.0
# DEPENDS       :apt-get install gamin
# DEPENDS       :gamin/tests/.lib/testgam
# LOCATION      :/usr/local/sbin/gamin-test.sh

# https://people.gnome.org/~veillard/gamin/debug.html

TESTGAM="/usr/local/sbin/testgam"

[ -x "$TESTGAM" ] || exit 1

Sudo_virtual() {
GAMTMP="$(sudo -u virtual -- mktemp)"
trap "sudo -u virtual -- rm -f '$GAMTMP'" EXIT HUP INT QUIT PIPE TERM

echo -e "connect test\npending\nsleep 1\ndisconnect" > "$GAMTMP"
sudo -u virtual -- "$TESTGAM" "$GAMTMP" \
    | grep -q "pending 0"
}

# Expected output:
#     connected to test
#     pending 0
#     disconnected
# Exit status of grep is 1 if not found
"$TESTGAM" <(echo -e "connect test\npending\nsleep 1\ndisconnect") \
    | grep -q "pending 0"
