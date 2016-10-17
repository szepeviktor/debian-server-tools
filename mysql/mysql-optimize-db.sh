#!/bin/bash
#
# https://www.percona.com/blog/2010/12/09/mysql-optimize-tables-innodb-stop/
#
# VERSION       :0.1.1
# LOCATION      :/usr/local/sbin/mysql-optimize-db.sh
# CRON-EXAMPLE  :04 4	* * 0	root	/usr/local/sbin/mysql-optimize-db.sh DATABASE-NAME

DBNAME="${1:-DEFAULT-DB-NAME}"

CHECK_OUTPUT="$(/usr/bin/mysqlcheck --silent --check --extended "$DBNAME")"
if [ $? -ne 0 ] || [ -n "$CHECK_OUTPUT" ]; then
    echo "Corrupt tables in ${DBNAME}" 1>&2
    exit 1
fi

/usr/bin/mysqlcheck --silent --optimize "$DBNAME" > /dev/null
if [ $? -ne 0 ]; then
    echo "Optimization failed for ${DBNAME}" 1>&2
    exit 1
fi

exit 0
