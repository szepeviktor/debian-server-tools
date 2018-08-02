#!/bin/bash
#
# Adatbázis migrálás fejlesztő szerverre.
#
# DEPENDS       :apt-get install mariadb-client pv
# CONFIG        :~/.ssh/config

TARGET_HOST="develop1"

SOURCE_DB="$1"
TARGET_DB="$2"

set -e

hash pv 2>/dev/null

test -n "$SOURCE_DB"
test -n "$TARGET_DB"

echo "Forrás adatbázis: ${SOURCE}"

# Dump teszt
mysqldump --no-create-info --no-data "$SOURCE" >/dev/null

{
    echo "$TARGET_DB"
    mysqldump --events --routines "$SOURCE_DB" | gzip -n
} | pv --rate | ssh -T "$TARGET_HOST"
