-- The user on the source host should have enough privileges to run mysqldump.

-- EDIT here
SET @dumper_user = "'sourceuser'";
SET @dumper_object = "`wildcard%`.*";

SET @dumper_query = CONCAT("GRANT SELECT, LOCK TABLES, EVENT ON ", @dumper_object,
    " TO ", @dumper_user, "@'localhost'",
    " IDENTIFIED WITH unix_socket");

-- SET @dumper_query = CONCAT("REVOKE SELECT, LOCK TABLES, EVENT ON ", @dumper_object,
--     " FROM ", @dumper_user, "@'localhost'");

PREPARE dumper_stmt FROM @dumper_query;
EXECUTE dumper_stmt;
DEALLOCATE PREPARE dumper_stmt;

FLUSH PRIVILEGES;
