### MariaDB upgrade error message: *Installation of system tables failed!*

```bash
mcedit +210 /var/lib/dpkg/info/mariadb-server-10.0.postinst
```

Comment out `#echo "$password_column_fix_query"`

### UNIX_SOCKET Authentication Plugin

```sql
INSTALL PLUGIN unix_socket SONAME 'auth_socket';
CREATE USER username IDENTIFIED WITH unix_socket;
```

### Drop all tables

http://nathan.rambeck.org/blog/28-drop-all-mysql-tables-command-line

```bash
# check for credentials in ~/.my.cnf
mysqldump --no-create-info --no-data information_schema > /dev/null && echo "USE information_schema;" | mysql

mysqldump --no-data <DATABASE> | grep "^DROP TABLE IF EXISTS " | mysql
```

### Check and optimize a databases

```bash
# Check for credentials in ~/.my.cnf
mysqlcheck information_schema

mysqlcheck --check --all-databases
mysqlcheck --check <DATABASE>

mysqlcheck --optimize --all-databases
mysqlcheck --optimize <DATABASE>

# Repair
#mysqlcheck --auto-repair <DATABASE>
```

### Check tables with wp-cli

```bash
wp db query "CHECK TABLE $(wp db tables | paste -s -d',');"
```

### Pre and Post import

https://dev.mysql.com/doc/refman/5.5/en/optimizing-innodb-bulk-data-loading.html

```sql
SET autocommit=0;
SET unique_checks=0;
SET foreign_key_checks=0;

-- ... the dump ...

COMMIT;
SET autocommit=1;
SET unique_checks=1;
SET foreign_key_checks=1;
```

### Percona Toolkit

http://www.percona.com/software/percona-toolkit

```bash
# http://www.percona.com/doc/percona-xtrabackup/2.2/innobackupex/incremental_backups_innobackupex.html
#innobackupex /var/archives/sql/

#TO_LSN="$(grep -o "^to_lsn\s*=\s*[0-9]\+$" ${LAST}/xtrabackup_checkpoints | cut -d' ' -f3)"
#innobackupex --incremental /var/archives/sql/ --incremental-lsn="$TO_LSN" >> /logfile 2>&1

innobackupex --incremental /var/archives/sql/ --incremental-basedir=/var/archives/sql/${$LAST_BACKUP} >> /logfile 2>&1

if tail -n 1 /logfile | grep -q "completed OK!$";then
```

### MySQL Levenshtein

[MySQL Levenshtein and Damerau-Levenshtein UDF’s](https://samjlevy.com/mysql-levenshtein-and-damerau-levenshtein-udfs/)

### MySQL timezone

```bash
# Import TZ data
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql
# Ubuntu mysql_tzinfo_to_sql /usr/share/zoneinfo | sed "s/'Local time zone must be set--see zic manual page'/'UNSET'/g" | mysql mysql
editor /etc/mysql/conf.d/timezone.cnf
#     [mysqld]
#     default-time-zone = Europe/Budapest
service mysql restart
date "+%F %T"; echo "SELECT NOW();" | mysql --skip-column-names
```
