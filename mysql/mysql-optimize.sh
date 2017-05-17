#!/bin/bash
#
# Optimize all MySQL tables.
#
# https://www.justin.my/2010/09/optimize-only-fragmented-tables-in-mysql/
# https://www.percona.com/blog/2010/12/09/mysql-optimize-tables-innodb-stop/
#
# VERSION       :0.2.0
# LOCATION      :/usr/local/sbin/mysql-optimize.sh

# 30%
declare -r -i FRAG_MIN="30"
# 200 MB
declare -r -i DATALENGTH_MAX="200000000"

set -e

DATABASES="$(mysql --skip-column-names --batch -e "SHOW DATABASES;" | grep -vEx "mysql|information_schema|performance_schema")"

while read -r DATABASE; do
    # Check
    mysqlcheck --silent --check --extended "$DATABASE"

    # 1                                                  7                                        10
    # Name Engine Version Row_format Rows Avg_row_length Data_length Max_data_length Index_length Data_free Auto_increment Create_time Update_time Check_time Collation Checksum Create_options Comment
    TABLESTATUS="$(mysql --skip-column-names --batch -e "SHOW TABLE STATUS;" "$DATABASE" | cut -f 1,7,10)"
    while read -r TABLENAME DATALENGTH DATAFREE; do
        if [ "$DATAFREE" == NULL ] || [ "$DATAFREE" -le 0 ]; then
            continue
        fi

        # Low fragmentation
        FRAG="$((DATAFREE * 100 / DATALENGTH))"
        if [ "$FRAG" -lt "$FRAG_MIN" ]; then
            continue
        fi

        # Big table
        if [ "$DATALENGTH" -gt "$DATALENGTH_MAX" ]; then
            echo "ERROR: ${DATABASE}.${TABLENAME} is a big table" 1>&2
            exit 101
        fi

        echo "${DATABASE}.${TABLENAME} fragmentation = ${FRAG}%, optimizing ..."
        mysqlcheck --silent --optimize "$DATABASE" "$TABLENAME"
    done <<< "$TABLESTATUS"
done <<< "$DATABASES"
