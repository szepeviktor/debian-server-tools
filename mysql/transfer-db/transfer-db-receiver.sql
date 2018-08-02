-- The user on the target host should have all privileges to import a database.

-- EDIT here
SET @import_user = "'dbtransferadmin'";
SET @import_object = "`wildcard%`.*";

SET @import_query = CONCAT("GRANT ALL PRIVILEGES ON ", @import_object,
    " TO ", @import_user, "@'localhost'",
    " IDENTIFIED WITH unix_socket");

-- SET @import_query = CONCAT("REVOKE ALL PRIVILEGES ON ", @import_object,
--     " FROM ", @import_user, "@'localhost'");

PREPARE import_stmt FROM @import_query;
EXECUTE import_stmt;
DEALLOCATE PREPARE import_stmt;

FLUSH PRIVILEGES;
