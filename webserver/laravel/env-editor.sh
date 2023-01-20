#!/bin/bash
#
# Edit Laravel's .env file.
#
# DEPENDS       :php-cachetool
# LOCATION      :/usr/local/bin/env-editor.sh

set -e

if [ "${EUID}" -lt 1000 ]; then
    echo "You need to be a normal user." 1>&2
    exit 10
fi
if ! [ -w .env ]; then
    echo ".env file not found or not writable." 1>&2
    exit 11
fi

editor .env
./artisan config:cache
./artisan queue:restart
cachetool opcache:reset --verbose

echo "OK."
