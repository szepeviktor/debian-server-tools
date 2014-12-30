## Criteria

- speed
- compression (speed, efficiency)
- encryption (CPU instruction test)
- deduplication: file level, block level, rolling hash (sliding window), soft (hash) collision, multiple backup sources
- source file modification detection (file meta data/file content) on incremental backups (disk read throughput)
- error/interruption/network failure handling, retries
- exclusion support (file list/glob/regexp)
- one filesystem restriction
- integrity checking (verify backups)
- recovery record for damaged backups
- backup target handling on incremental backups (create-only/modified old backup files)
- remote source, remote target support
- network traffic
- network protocols (S3, Galcier, swift, hubiC, S/FTP, SMTP, Dropbox)
- keep policy (days, weeks, months, years)
- backup/no-backup [tag files](http://www.brynosaurus.com/cachedir/spec.html) for directories
- list backups, backup contents, mount as fuse
- logging, debugging

### Options

- separate backups (etc, homes, databases, mail accounts, websites)
- excludes (DB, cache, spool, tmp)
- logging, reporting success/failure
- monitoring: send email
- nice, ionice, bandwidth throttling

### Backup programs

- https://github.com/zbackup/zbackup
- https://github.com/jborg/attic
- http://obnam.org/
