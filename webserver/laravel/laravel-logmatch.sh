#!/bin/bash
#
# Find matching lines in Laravel and Apache logs.
#

# EDIT here
APACHE_ACCESS_LOG="/var/log/apache2/project-ssl-access.log"
APACHE_ERROR_LOG="/var/log/apache2/project-ssl-error.log"

set -e

LARAVEL_LOG="$1"

test -r "$APACHE_ACCESS_LOG"
test -r "$APACHE_ERROR_LOG"
test -r "$LARAVEL_LOG"

while read -r LARAVEL_ITEM; do
    # Skip on non-timestamped lines
    if [[ ! "$LARAVEL_ITEM" =~ ^\[[0-9] ]]; then
        continue
    fi

    # Find the time stamp
    LARAVEL_TIME="$(sed -n -e 's#^\[\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\)\] .*#\1#p' <<< "$LARAVEL_ITEM")"
    # Convert format
    APACHE_TIME="$(date --date "$LARAVEL_TIME" "+%d/%b/%Y:%H:%M:%S")"
    APACHE_ERROR_TIME="$(date --date "$LARAVEL_TIME" "+%a %b %d %H:%M:%S")"

    # Display line pairs
    echo "$LARAVEL_ITEM"
    grep -F " [${APACHE_TIME} +" "$APACHE_ACCESS_LOG" || echo "Not found!"
    grep -F "[${APACHE_ERROR_TIME}." "$APACHE_ERROR_LOG" || true
    echo "--"
done < "$LARAVEL_LOG"

echo "--- END ---"
