#!/bin/bash
#
# Build Courier MTA from Debian testing.
#
# DEPENDS       :docker pull szepeviktor/jessie-backport
# GIT           :https://anonscm.debian.org/git/collab-maint/courier-unicode.git
# GIT           :https://anonscm.debian.org/git/collab-maint/courier-authlib.git
# GIT           :https://anonscm.debian.org/git/collab-maint/courier.git

Build() {
    local PKG="$1"

    docker run --rm --tty --volume /opt/results:/opt/results \
        --env PACKAGE="$PKG" szepeviktor/jessie-backport
}

set -e

[ -d /opt/results ] || mkdir /opt/results

# Build it ----------
Build courier-unicode/testing
Build courier-authlib/testing
Build courier/testing

set +x

echo "3×OK."

# Main IP address
ROUTER="$(ip -4 route show to default | sed -n -e '0,/^default via \(\S\+\).*$/s//\1/p')"
IP="$(ip -4 route get "$ROUTER" | sed -n -e '0,/^.*\ssrc \(\S\+\).*$/s//\1/p')"

echo "scp -r root@${IP}:/opt/results/ ./"
