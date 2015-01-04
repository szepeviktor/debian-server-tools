## Backup criteria list

- overall time it takes to finish
- compression (CPU usage, efficiency)
- encryption (passphrase, public&private key, usage of CPU instructions)
- deduplication: file level, block level, rolling hash (sliding window), soft (hash) collision, over multiple backup sources
- source file modification detection (file meta data, file content) on incremental backups (disk read throughput)
- error, interruption, network failure handling, retries
- exclusion support (file list/glob/regexp)
- backup/no-backup [tag files](http://www.brynosaurus.com/cachedir/spec.html) for directories
- one filesystem restriction
- integrity checking (verify backups)
- recovery record (damaged backups)
- backup target handling on incremental backups (read-and-create-only or updating also), uploading to cold storage
- remote source, remote target support
- network traffic
- network protocols (S3, Glacier, swift, hubiC, S/FTP, SMTP, Dropbox)
- keep policy (days, weeks, months, years), deleting old increments
- list backups, backup contents, mount as fuse
- logging, debugging
- responsive support forum

### Options

- separate backups (per volume, etc, homes, databases, mail accounts, websites)
- excludes (VCS, DB, cache, spool, tmp)
- logging, reporting success/failure
- monitoring
- nice, ionice, bandwidth throttling

### Programs

- http://duplicity.nongnu.org/
- http://obnam.org/
- https://github.com/jborg/attic
- https://github.com/zbackup/zbackup
- https://github.com/bup/bup

### Backup all GitHub repos

```bash
GH_USER="szepeviktor"
wget -qO- "https://api.github.com/users/${GH_USER}/repos?per_page=100"|grep '"clone_url"'|cut -d'"' -f4 > github.repos
cat github.repos|xargs -L 1 git clone
```
