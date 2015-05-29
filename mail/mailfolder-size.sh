#!/bin/bash

MAILROOT="/var/mail/"

find "$MAILROOT" -type d -wholename "*/cur" \
    | while read FULLPATH; do
        RELPATH="${FULLPATH#$MAILROOT}"
        du -sk "$FULLPATH"
    done \
    | sort -n -r | head
