#!/bin/sh
#
# VERSION       :0.1
# LOCATION      :/usr/local/sbin/nginx-reload.sh

flock -x "/var/lock/nginx-reload" -c /usr/local/sbin/nginx-reload-worker.sh

logger -t "nginx-reload[$$]" "Reloading OK"

