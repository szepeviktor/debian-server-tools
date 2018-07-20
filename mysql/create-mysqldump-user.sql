-- This user has enough privileges to run mysqldump.

-- EDIT
SET @dumper_user = "'sql-user'";
SET @dumper_object = "`database-name%`.*";

SET @dumper_query = CONCAT("GRANT SELECT, LOCK TABLES, EVENT ON ", @dumper_object,
    " TO ", @dumper_user, "@'localhost'",
    " IDENTIFIED WITH unix_socket");

-- SET @dumper_query = CONCAT("REVOKE SELECT, LOCK TABLES, EVENT ON ", @dumper_object,
--     " FROM ", @dumper_user, "@'localhost'");

PREPARE dumper_stmt FROM @dumper_query;
EXECUTE dumper_stmt;
DEALLOCATE PREPARE dumper_stmt;

FLUSH PRIVILEGES;
