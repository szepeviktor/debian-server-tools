#!/bin/bash
#
# List all files with global helper calls.
#

HELPERS_REGEXP="$(
    grep -Erh '^\s*function\s+\w+\(' vendor/laravel/framework/src/ \
        | sed -n -e 's#^\s\+function\s\+\(\w\+\).*$#\1#p' \
        | grep -vFx '__' \
        | sort \
        | paste -d '|' -s
)"

grep -rEnw "[^>:](${HELPERS_REGEXP})\\(" app/ # resources/
