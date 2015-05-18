#!/bin/sh
#
# VERSION       :0.1
# LOCATION      :/usr/local/sbin/nginx-reload-worker.sh

Die() {
    local RET=$1
    shift
    echo -e "$@" >&2
    exit "$RET"
}

# Hold other calls.
sleep 5

service nginx reload || Die 1 "nginx reload error"
