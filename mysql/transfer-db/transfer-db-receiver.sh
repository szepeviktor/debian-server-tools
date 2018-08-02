#!/bin/bash
#
# Adatbázis migrálás fogadó szkript.
#
# DEPENDS       :apt-get install mariadb-client
# LOCATION      :/usr/local/bin/transfer-db-receiver.sh

RECEIVER_HOME="$HOME"

set -e

# Első sor: adatbázis név
read -r DB_NAME

# Üres-e a név
test -n "$DB_NAME"

echo "Cél adatbázis neve: ${DB_NAME}"

echo "Dump teszt"
mysqldump --no-create-info --no-data "$DB_NAME" >/dev/null

echo "Mentés"
SAVE_DUMP="${RECEIVER_HOME}/save-${DB_NAME}.sql.gz"
touch "$SAVE_DUMP"
chmod 0640 "$SAVE_DUMP"
mysqldump --events --routines "$DB_NAME" | gzip -n >"$SAVE_DUMP"

echo "Eldobás"
echo "DROP DATABASE ${DB_NAME};" | mysql

echo "Létrehozás"
echo "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4;" | mysql

echo "Táblák feltöltése"
gunzip | mysql "$DB_NAME"

echo "OK."
