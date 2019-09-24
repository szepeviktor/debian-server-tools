# Restore database backed up by innobackupex

https://www.percona.com/doc/percona-xtrabackup/2.3/innobackupex/incremental_backups_innobackupex.html

```bash
# Dump current db
wp db dump

# Copy base and incremental backup to a temporary directory
mkdir /root/db-restore
cd /media/server-backup.s3ql/innodb/

# Look at lsn-s
cd /root/db-restore/
grep -E "^innodb_(from|to)_lsn" */xtrabackup_info

# Prepare
innobackupex --apply-log --redo-only BASE-DIR
grep -w LOG-SEQUENCE-NUMBER INCREMENTAL-DIR/xtrabackup_info
innobackupex --apply-log --redo-only BASE-DIR --incremental-dir=INCREMENTAL-DIR
innobackupex --apply-log BASE-DIR

# Fix permissions
chown -R mysql:mysql .

# # Second mysql instance
# mkdir /var/lib/mysql2; chown mysql:mysql /var/lib/mysql2; chmod 0700 /var/lib/mysql2
# mv -f BASE-DIR/* /var/lib/mysql2/
# cp -a /etc/mysql /etc/mysql2
# # Change *mysql* to *mysql2*
# # Start, Use and Stop
# su - mysql -s /bin/sh -c "/usr/bin/mysqld_safe --defaults-file=/etc/mysql2/my.cnf"
# mysql -S /run/mysqld/mysqld2.sock
# mysqladmin --defaults-file=/etc/mysql2/my.cnf -S /run/mysqld/mysqld2.sock shutdown

# Restore
service mysql stop
mv -v /var/lib/mysql/* /root/db-restore/
innobackupex --copy-back BASE-DIR
# Copy back Debian files
cp /root/db-restore/debian-10.0.flag /var/lib/mysql/
cp /root/db-restore/multi-master.info /var/lib/mysql/
cp /root/db-restore/mysql_upgrade_info /var/lib/mysql/

# Flush WordPress cache
wp cache flush

# Restart MySQL server
service mysql start &
tail -f /var/log/syslog
```
