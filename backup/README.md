## Criteria

- compression (speed, efficiency)
- encryption
- speed
- integrity checking
- fault tolerance
- deduplication: file, block, rolling hash (sliding window), soft collision, multiple backup sources
- remote source, remote target
- source file modification detection (file content/file meta data) on incremental backups (disk throughput)
- backup file modification on incremental backups (create-only/modified old backup files)
- network traffic
- protocols (S3, swift, FTP)
- keep policy
- one filesystem at a time
- backup/no backup [tag files](http://www.brynosaurus.com/cachedir/spec.html)

### Options

- separate backups (etc, home, DB, mail, web)
- excludes (DB, cache, spool, tmp)
- logging
- monitoring: send email

### Softwares

- https://github.com/zbackup/zbackup
- https://github.com/jborg/attic
- http://obnam.org/
