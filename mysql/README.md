### Drop all tables

http://nathan.rambeck.org/blog/28-drop-all-mysql-tables-command-line

```bash
# check for credentials in ~/.my.cnf
mysqldump --no-create-info --no-data information_schema > /dev/null && echo "USE information_schema;" | mysql

mysqldump --no-data <DATABASE> | grep "^DROP TABLE IF EXISTS " | ionice mysql
```

### Alter table engine

http://georgepavlides.info/?p=628

```sql
-- to ARIA
SET @DBNAME = '<DATABASE>
SELECT CONCAT( 'ALTER TABLE `', tbl.`TABLE_SCHEMA`, '`.`', tbl.`TABLE_NAME`, '` ENGINE = Aria TRANSACTIONAL = 0 PAGE_CHECKSUM = 0;' )
    FROM  `information_schema`.`TABLES` tbl
    WHERE tbl.`TABLE_SCHEMA` =  @DBNAME
    LIMIT 0,1000;

-- to InnoDB
SET @DBNAME = '<DATABASE>
SELECT CONCAT( 'ALTER TABLE `', tbl.`TABLE_SCHEMA` ,  '`.`', tbl.`TABLE_NAME` , '` ENGINE = InnoDB;' )
    FROM  `information_schema`.`TABLES` tbl
    WHERE tbl.`TABLE_SCHEMA` =  @DBNAME
    LIMIT 0,1000;
```

```bash
# create alter.sql with substituted <DATABASE> name
cat alter.sql | mysql | ionice mysql
```

### Check an optimize databases

```bash
# check for credentials in ~/.my.cnf
mysqlcheck information_schema

ionice mysqlcheck --check --all-databases
ionice mysqlcheck --check <DATABASE>

ionice mysqlcheck --optimize --all-databases
ionice mysqlcheck --optimize <DATABASE>

#ionice mysqlcheck --auto-repair <DATABASE>
```

### Check tables with wp-cli

```bash
wp db query "CHECK TABLE $(wp db tables | paste -s -d',');"
```

### Pre and Post import

-- https://dev.mysql.com/doc/refman/5.5/en/optimizing-innodb-bulk-data-loading.html

```sql
SET autocommit=0;
SET unique_checks=0;
SET foreign_key_checks=0;
```

... the dump ...

```sql
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

#TO_LSN="$(grep -o "^to_lsn\s*=\s*[0-9]\+$" ${LAST}/xtrabackup_checkpoints | cut -d' ' -f 3)"
#innobackupex --incremental /var/archives/sql/ --incremental-lsn="$TO_LSN" >> /logfile 2>&1

innobackupex --incremental /var/archives/sql/ --incremental-basedir=/var/archives/sql/${$LAST_BACKUP} >> /logfile 2>&1

if tail -n 1 /logfile | grep -q "completed OK!$";then
```
