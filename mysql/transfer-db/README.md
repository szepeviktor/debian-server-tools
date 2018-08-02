# Transfer databases between hosts

# Source host

- Edit and install `transfer-db.sh`
- Set up SSH config and the SSH key
- Set up unix socket based MySQL authentication for the project's Linux user
- Grant privileges by editing and executing `transfer-db.sql`

# Target host

- Create Linux user
- Add the SSH public key to `authorized_keys2` with `restrict,command="/usr/local/bin/transfer-db-receiver.sh"`
- Install `transfer-db-receiver.sh`
- Grant privileges by editing and executing `transfer-db-receiver.sql`

Test!
