#!/bin/sh
#
# Start szepeviktor/jessie-backport.
#

docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="$1" szepeviktor/jessie-backport
