#!/bin/bash
#
# Create database and database user from wp-config.php
# Needs user, password and default-character-set in ~/.my.cnf [mysql] section.
#
# VERSION       :0.1.1
# DATE          :2015-07-20
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/wp-createdb.sh

WP_CONFIG="./wp-config.php"

Get_wpconfig_var() {
    local VAR="$1"

    # UNIX or Windows lineends
    if ! grep "^define.*${VAR}.*;.\?$" "$WP_CONFIG" | cut -d"'" -f4; then
        echo "Cannot find variable (${VAR})" >&2
        exit 1
    fi
}

which mysql &> /dev/null || exit 1
[ -r "$WP_CONFIG" ] || exit 2
# Check credentials
echo "exit" | mysql || exit 3

DBNAME="$(Get_wpconfig_var "DB_NAME")"
DBUSER="$(Get_wpconfig_var "DB_USER")"
DBPASS="$(Get_wpconfig_var "DB_PASSWORD")"
DBHOST="$(Get_wpconfig_var "DB_HOST")"
DBCHARSET="$(Get_wpconfig_var "DB_CHARSET")"
# "DB_COLLATE"

# Exit on non-UTF8 charset
[[ "$DBCHARSET" =~ utf8 ]] || exit 99

echo "Database: ${DBNAME}"
echo "User:     ${DBUSER}"
echo "Password: ${DBPASS}"
echo "Host:     ${DBHOST}"
echo "Charset:  ${DBCHARSET}"
echo
read -p "CREATE DATABASE? " -n 1

[ "$DBHOST" == "localhost" ] || echo "Connecting to ${DBHOST} ..."

mysql --default-character-set=utf8 --host="$DBHOST" <<EOF || echo "Couldn't setup up database (MySQL error: $?)" >&2
CREATE DATABASE IF NOT EXISTS \`${DBNAME}\`
    CHARACTER SET 'utf8'
    COLLATE 'utf8_general_ci';
-- "GRANT ALL PRIVILEGES" creates the user
-- CREATE USER '${DBUSER}'@'${DBHOST}' IDENTIFIED BY '${DBPASS}';
GRANT ALL PRIVILEGES ON \`${DBNAME}\`.* TO '${DBUSER}'@'${DBHOST}'
    IDENTIFIED BY '${DBPASS}';
FLUSH PRIVILEGES;
EOF
