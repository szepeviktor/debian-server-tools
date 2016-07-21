#!/bin/sh
#
# VERSION       :0.2
# LOCATION      :/usr/local/sbin/nginx-reload.sh

WORKER="/usr/local/sbin/nginx-reload-worker.sh"

# Other reload requests must wait.
# "-w 5" - Drop multiple requests but the first one.
flock -x -w 5 "/var/lock/nginx-reload" -c "$WORKER"

logger -t "nginx-reload[$$]" "Reloading OK"

# ? https://github.com/ByteInternet/nginx_config_reloader
