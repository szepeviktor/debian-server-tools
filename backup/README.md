## Backup criteria list

- Overall **time** it takes to finish
- **Compression** (CPU usage, efficiency)
- **Encryption** (passphrase, public&private key, usage of CPU instructions)
- **Deduplication** file level, block level, rolling hash (sliding window), soft (hash) collision, over multiple backup sources
- Detection of **modified source** files (meta data, content) on incremental backups (save disk reads)
- Upload only modified source files (save **bandwidth**)
- Software error, interruption, network **failure handling**, retries
- **Integrity** checking (checksum for verifying backups)
- **Recovery** record (damaged backups)
- **Exclusion** support (file list, glob, regexp)
- Backup/no-backup **[tag files](http://www.brynosaurus.com/cachedir/spec.html)** for directories
- **One filesystem** restriction
- Backup target handling on incremental backups ( **read and create only** or updating also), uploading to cold storage
- **Remote** source, remote target support
- **Low network traffic**
- Network **protocols** (S3, Glacier, swift, hubiC, S/FTP, SMTP, Dropbox)
- **Keep policy** (days, weeks, months, years), deletion of old versions
- **List** backups, backup contents, mount as fuse
- **Logging**, debugging
- Responsive **support forum**

### Options

- Separate backups (per volume, /etc, homes, databases, mail, websites)
- Excludes (VCS, known files (WordPress core), DB, cache, spool, tmp)
- Logging, reporting success and failure
- Monitoring
- `nice`, `ionice`, bandwidth throttling

### Programs

- http://mattmahoney.net/dc/zpaq.html
- http://obnam.org/
- http://duplicity.nongnu.org/
- https://github.com/jborg/attic
- https://github.com/zbackup/zbackup
- https://github.com/bup/bup
- http://moinakg.github.io/pcompress/
- compression: http://nanozip.net/
- http://www.byronknoll.com/cmix.html

### Backup all GitHub repos

```bash
GH_USER="szepeviktor"
wget -qO- "https://api.github.com/users/${GH_USER}/repos?per_page=100"|grep '"clone_url"'|cut -d'"' -f4 > github.repos
cat github.repos|xargs -L 1 git clone
```

### S3QL flush before umount

- synchronize: fsync(2)
- upload: s3qlctrl flushcache
- unmount: umount.s3ql

### Storage

[OVH Public Cloud Object Storage](https://docs.ovh.com/pages/releaseview.action?pageId=18121668)
[OVH/hubiC object storage](https://hubic.com/en/offers/)
[OVH/KS-1 server](https://www.kimsufi.com/en/) 500 GB €5/m
[HostHatch Storage VPS](https://hosthatch.com/storage-vps) 250 GB €5/m

### mega.co.nz CLI

https://packages.debian.org/unstable/megatools
