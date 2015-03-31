-- http://stackoverflow.com/questions/12403662/how-to-drop-all-mysql-tables-from-the-command-line/12403746#12403746

SET FOREIGN_KEY_CHECKS = 0;
SET @wp_tables = NULL;
SELECT GROUP_CONCAT(table_schema, '.', table_name) INTO @wp_tables
    FROM information_schema.tables
    WHERE table_schema = DATABASE();

SET @wp_tables = CONCAT('DROP TABLE ', @wp_tables);

PREPARE wp_stmt FROM @wp_tables;
EXECUTE wp_stmt;
DEALLOCATE PREPARE wp_stmt;
SET FOREIGN_KEY_CHECKS = 1;
