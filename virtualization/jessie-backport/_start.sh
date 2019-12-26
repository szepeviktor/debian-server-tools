#!/bin/sh
#
# Start szepeviktor/jessie-backport.
#

[ -d /opt/results ] || exit 100

docker run --rm --tty --ulimit nofile=2048 --volume /opt/results:/opt/results --env PACKAGE="$1" szepeviktor/jessie-backport
