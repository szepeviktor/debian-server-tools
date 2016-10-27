#!/bin/sh
#
# Start szepeviktor/jessie-backport.
#

[ -d /opt/results ] || exit 100

docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="$1" szepeviktor/jessie-backport
