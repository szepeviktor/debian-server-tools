#!/bin/sh

error() {
    local RET=$1
    shift
    echo -e "$@" >&2
    exit "$RET"
}

sleep 5
service nginx reload || error 2 "nginx reload error"
