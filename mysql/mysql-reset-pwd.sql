SET @my_password = '<PASSWORD>';

UPDATE mysql.user SET Password=PASSWORD(@my_password) WHERE User='root';
FLUSH PRIVILEGES;
