# MariaDB 10.1 Perfomance tuning

Videos by Aurimas Mikalauskas: https://www.youtube.com/channel/UCMu7hy-Ji8OWoxAqzbj7LhQ/videos

Table engine: InnoDB

### [Suggested configuration](http://www.speedemy.com/17-key-mysql-config-file-settings-mysql-5-7-proof/)

```ini
[mysqld]
slow_query_log_file         = /var/log/mysql/mariadb-slow.log

query_cache_type            = ON
query_cache_size            = 256M

innodb_stats_on_metadata    = OFF
innodb_buffer_pool_size     = {50% of RAM}
innodb_log_file_size        = 48M
innodb_flush_method         = O_DIRECT
innodb_thread_concurrency   = {CPU CORES - 1}
```

### Slow log analysis

- Install Percona Tools: `apt-get install percona-toolkit`
- Remove old slow log: `rm /var/log/mysql/mariadb-slow.log`
- Start SQL shell: `mysql`

```sql
SHOW GLOBAL VARIABLES LIKE "slow_query_log_file";
SET GLOBAL long_query_time=0.050; -- Longer than 50 msec
SET GLOBAL log_queries_not_using_indexes=OFF; -- Do not log query without index
SET GLOBAL slow_query_log=ON; -- Start logging!
```

- Wait 30 minutes!
- Stop logging: `SET GLOBAL slow_query_log=OFF;`
- Process slow log: `pt-query-digest --report-histogram Query_time /var/log/mysql/mariadb-slow.log >~/slow.log.out`

1. Examine top queries in "Profile"
1. Look at "Query_time distribution" per query
1. Investigate queries with `EXPLAIN SELECT ...` in SQL shell

### Useful status queries

```sql
SHOW GLOBAL VARIABLES LIKE "innodb_buffer_pool_%";
SHOW STATUS LIKE 'Innodb_buffer%';
SHOW STATUS LIKE 'Qcache%';
SHOW FULL PROCESSLIST;
```

### SQL code formatter

https://sqlformat.org/
