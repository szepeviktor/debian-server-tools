#!/bin/bash
#
# Install system-backup.sh
#

set -e

mkdir /root/.s3ql

(
    cd /usr/local/src/debian-server-tools/
    ./install.sh backup/system-backup.sh
)

# Create S3QL configuration file
cat >/root/.s3ql/authinfo2 <<EOF
[ovh]
#storage-url: swiftks://auth.cloud.ovh.net/OS_REGION_NAME:CONTAINER/PREFIX_
#backend-options: domain=Default
[aws]
#storage-url: local:///media/backup-server.sshfs
# Frankfurt: eu-central-1 Ireland: eu-west-1 London: eu-west-2 Paris: eu-west-3
storage-url: s3://S3_REGION/S3_BUCKET/PREFIX_
backend-login: IAM_ACCESS_KEY_ID
backend-password: IAM_SECRET_ACCESS_KEY
fs-passphrase: $(apg -m 32 -n 1)
EOF

editor /root/.s3ql/authinfo2
chmod 0600 /root/.s3ql/authinfo2

# Create script configuration file
mkdir -p /root/.config/system-backup
cat >/root/.config/system-backup/configuration <<EOF
STORAGE_URL="$(sed -n -e 's|^storage-url:\s*\(\S\+\)$|\1|p' /root/.s3ql/authinfo2)"
TARGET="/media/server-backup.s3ql"
#MOUNT_OPTIONS="--threads 4 --compress zlib-5"
MOUNT_OPTIONS="--compress zlib-5"
AUTHFILE="/root/.s3ql/authinfo2"
#DB_EXCLUDE="excluded-db1|excluded-db2"
#SKIP_DB_SCHEMA_DIFF="YES"
HCHK_URL="https://hc-ping.com/aaaaaaaa-1111-2222-3333-bbbbbbbbbbbb"
EOF

editor /root/.config/system-backup/configuration

# Add an [xtrabackup] section to /root/.my.cnf
if ! echo 'SELECT VERSION();' | mysql -N; then
    cat >>/root/.my.cnf <<"EOF"

[xtrabackup]
user=root
pass=MYSQL-PASSWORD
default-character-set=utf8
EOF

    editor /root/.my.cnf
fi

# Format storage and Create target directory
(
    # shellcheck disable=SC1091
    source /root/.config/system-backup/configuration
    test -n "$STORAGE_URL"
    # Show passphrase
    grep '^fs-passphrase:' /root/.s3ql/authinfo2
    mkfs.s3ql "$STORAGE_URL"
    test -n "$TARGET"
    mkdir -p "$TARGET"
)

echo "OK."
