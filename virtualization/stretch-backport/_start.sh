#!/bin/sh
#
# Start szepeviktor/stretch-backport.
#

[ -d /opt/results ] || exit 100

docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="$1" szepeviktor/stretch-backport
