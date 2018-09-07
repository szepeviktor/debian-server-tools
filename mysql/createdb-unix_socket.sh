#!/bin/bash
#
# Create database and database user with sokcet authentication.
#
# VERSION       :0.2.0
# DATE          :2018-07-19
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/createdb.sh

Get_var() {
    local VAR="$1"
    local DEFAULT="$2"

    if [ -z "$DEFAULT" ]; then
        read -r -e -p "${VAR}? " DB_VALUE
    else
        read -r -e -i "$DEFAULT" -p "${VAR}? " DB_VALUE
    fi
    if [ -z "$DB_VALUE" ]; then
        echo "Cannot set variable (${VAR})" 1>&2
        exit 20
    fi
    echo "$DB_VALUE"
}

set -e

hash mysql 2> /dev/null

# Check database access
mysql --execute="EXIT"

DBNAME="$(Get_var "DB_NAME")"
DBUSER="$(Get_var "DB_USER")"
DBHOST="$(Get_var "DB_HOST" "localhost")"
DBCHARSET="$(Get_var "DB_CHARSET" "utf8")"
# "DB_COLLATE"

# Exit on non-UTF8 charset
if [[ ! "$DBCHARSET" =~ [Uu][Tt][Ff]8 ]]; then
    echo "DB_CHARSET is not 'UTF8'" 1>&2
    exit 10
fi

echo "Database: ${DBNAME}"
echo "User:     ${DBUSER}"
echo "Password: <unix_socket>"
echo "Host:     ${DBHOST}"
echo "Charset:  ${DBCHARSET}"
echo
read -r -p "CREATE DATABASE? " -n 1

if [ "$DBHOST" != localhost ]; then
    echo "Connecting to ${DBHOST} ..."
fi

mysql --default-character-set=utf8 --host="$DBHOST" <<EOF || echo "Couldn't setup up database (MySQL error: ${?})" 1>&2
CREATE DATABASE IF NOT EXISTS \`${DBNAME}\`
    CHARACTER SET 'utf8'
    COLLATE 'utf8_general_ci';
-- "GRANT ALL PRIVILEGES" creates the user
GRANT ALL PRIVILEGES ON \`${DBNAME}\`.*
    TO '${DBUSER}'@'${DBHOST}'
    IDENTIFIED WITH unix_socket;
FLUSH PRIVILEGES;
EOF
