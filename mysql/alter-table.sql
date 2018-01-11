-- Alter table engine
--
-- Usage:  mysql -N DATABASE-NAME < alter-table.sql | mysql
--
-- Source:  http://georgepavlides.info/?p=628


-- To Aria
-- https://mariadb.com/kb/en/mariadb/aria-storage-engine/
-- SET @engine_string = 'ENGINE = Aria, TRANSACTIONAL = 1, PAGE_CHECKSUM = 0';

-- To TokuDB w/LZMA
-- https://www.percona.com/doc/percona-server/5.6/tokudb/tokudb_compression.html
-- SET @engine_string = 'ENGINE = TokuDB, ROW_FORMAT=TOKUDB_LZMA';

-- To TokuDB w/Quick LZ
-- SET @engine_string = 'ENGINE = TokuDB, ROW_FORMAT=TOKUDB_QUICKLZ';

-- To InnoDB
-- Table compression algorithm (lz4) support from MariaDB 10.1.0
-- https://mariadb.com/kb/en/mariadb/innodb-xtradb-page-compression/
SET @engine_string = 'ENGINE = InnoDB';

SET @data_base = ( SELECT DATABASE() );

SELECT CONCAT(
    'ALTER TABLE `',
    `tbl`.`TABLE_SCHEMA`,
    '`.`',
    `tbl`.`TABLE_NAME`,
    '` ',
    @engine_string,
    ';' ) AS `alters`
  FROM `information_schema`.`TABLES` `tbl`
  WHERE `tbl`.`TABLE_SCHEMA` = @data_base
  LIMIT 0,1000;
