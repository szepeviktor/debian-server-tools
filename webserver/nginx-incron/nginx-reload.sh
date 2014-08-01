#!/bin/sh

flock -x "/var/lock/nginx-reload" -c nginx-reload-worker.sh
logger -t "nginx-reload[$$]" "Reloading OK"
