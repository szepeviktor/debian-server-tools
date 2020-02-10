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
- Backup target handling on incremental backups (**read and create/append only** or updating also), uploading to cold storage
- **Remote** source, remote target support
- **Low network traffic**
- Network **protocols** (S3, Amazon Glacier, OpenStack swift, hubiC, S/FTP, SMTP, Dropbox)
- **Keep policy** (days, weeks, months, years), deletion of old versions
- **List** backups, backup contents, mount as FUSE
- **Logging**, debugging
- Responsive **support forum**

### Options

- Separate backups (per volume, /etc, homes, databases, mail, websites)
- Excludes (VCS, known files (WordPress core), DB, cache, spool, tmp)
- Logging, reporting success and failure
- Monitoring
- `nice`, `ionice`, bandwidth throttling

### Programs

https://quixdb.github.io/squash-benchmark/

- :trophy: https://github.com/s3ql/s3ql (winner)
- http://mattmahoney.net/dc/zpaq.html
- http://obnam.org/
- http://duplicity.nongnu.org/
- https://github.com/jborg/attic
- https://github.com/zbackup/zbackup
- https://github.com/bup/bup
- http://moinakg.github.io/pcompress/
- http://www.byronknoll.com/cmix.html
- https://github.com/centaurean/density
- https://github.com/IlyaGrebnov/libbsc

### Compression

- http://nanozip.net/
- http://www.7-zip.org/ http://tukaani.org/xz/
- https://code.google.com/p/snappy/ https://github.com/kubo/snzip
- https://github.com/google/zopfli High compression zlib-compatible
- http://www.quicklz.com/
- [apt-get install lzop](http://www.lzop.org/lzop_man.php)
- [LZ4 is a very fast lossless compression algorithm](https://github.com/Cyan4973/lz4)
- [Zstd](https://fastcompression.blogspot.com/2015/01/zstd-stronger-compression-algorithm.html)

### Backup all GitHub repos

```bash
GH_USER="szepeviktor"
wget -qO- "https://api.github.com/users/${GH_USER}/repos?per_page=100"|grep '"clone_url"'|cut -d'"' -f4 >github.repos
cat github.repos|xargs -L1 git clone
```

### S3QL flush before umount

- synchronize: fsync(2)
- upload: sync && s3qlctrl flushcache
- unmount: umount.s3ql

### S3QL recover metadata from backup

Add to `/usr/lib/s3ql/s3ql/fsck.py` in `main()` after `if param['seq_no'] > seq_no:`

```python
        elif 's3ql_metadata' not in backend:
            log.warn('No remote metadata, recovering backup...')
            backend.rename('s3ql_metadata_bak_0', 's3ql_metadata')
            param['needs_fsck'] = True
```

### S3QL on BackBlaze B2

```bash
cat > ~/.s3ql/authinfo2 <<EOF
[blackbaze]
storage-url: b2://${B2_BUCKET}/${B2_PREFIX}_
backend-login: ${B2_ACCOUNT_ID}
backend-password: ${B2_APPLICATION_KEY}
fs-passphrase: $(apg -m32 -n1)
EOF
chmod -v 0600 ~/.s3ql/authinfo2
```

### S3QL on OVH

Paste OpenStack configuration into `openrc.sh`, set `OS_PASSWORD`

```bash
chmod -v 0600 openrc.sh
source openrc.sh
read -r -e -p "OS_CONTAINER=" OS_CONTAINER
cat > ~/.s3ql/authinfo2 <<EOF
[swiftks]
storage-url: swiftks://auth.cloud.ovh.net/${OS_REGION_NAME}:${OS_CONTAINER}
backend-options: domain=Default
backend-login: ${OS_TENANT_ID}:${OS_USERNAME}
backend-password: ${OS_PASSWORD}
fs-passphrase: $(apg -m32 -n1)
EOF
chmod -v 0600 ~/.s3ql/authinfo2
```

### S3QL on Oktawave OCS

```bash
cat > ~/.s3ql/authinfo2 <<EOF
[oktawave]
storage-url: swift://ocs-pl.oktawave.com/${OCS_CONTAINER}
backend-login: ${OCS_ACCOUNT}:${OCS_USER}
backend-password: ${OCS_PASSWORD}
fs-passphrase: $(apg -m32 -n1)
EOF
chmod -v 0600 ~/.s3ql/authinfo2
```

### S3QL on Amazon S3

```bash
cat > ~/.s3ql/authinfo2 <<EOF
[s3]
storage-url: s3://${S3_REGION}/${S3_BUCKET}/${S3_PREFIX}_
backend-login: ${IAM_ACCESS_KEY_ID}
backend-password: ${IAM_SECRET_ACCESS_KEY}
fs-passphrase: $(apg -m32 -n1)
EOF
chmod -v 0600 ~/.s3ql/authinfo2
```

| Region Name               | Region         |
| ------------------------- | -------------- |
| US East (N. Virginia)     | us-east-1*     |
| US East (Ohio)            | us-east-2      |
| US West (N. California)   | us-west-1      |
| US West (Oregon)          | us-west-2      |
| Canada (Central)          | ca-central-1   |
| Asia Pacific (Mumbai)     | ap-south-1     |
| Asia Pacific (Seoul)      | ap-northeast-2 |
| Asia Pacific (Singapore)  | ap-southeast-1 |
| Asia Pacific (Sydney)     | ap-southeast-2 |
| Asia Pacific (Tokyo)      | ap-northeast-1 |
| EU (Frankfurt)            | eu-central-1   |
| EU (Ireland)              | eu-west-1      |
| EU (London)               | eu-west-2      |
| EU (Paris)                | eu-west-3      |
| South America (São Paulo) | sa-east-1      |

Source: http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region

### S3QL on Selectel

```bash
cat > ~/.s3ql/authinfo2 <<EOF
[selectel]
storage-url: swift://auth.selcdn.ru/${OS_CONTAINER}
backend-login: ${OS_USERNAME}
backend-password: ${OS_PASSWORD}
fs-passphrase: $(apg -m32 -n1)
EOF
chmod -v 0600 ~/.s3ql/authinfo2
```

### S3QL on any S3

http://www.rath.org/s3ql-docs/backends.html

```bash
cat > ~/.s3ql/authinfo2 <<EOF
[s3]
storage-url: s3c://${S3_HOST}/${S3_BUCKET}/${S3_PREFIX}_
backend-login: ${ACCESS_KEY_ID}
backend-password: ${SECRET_ACCESS_KEY}
fs-passphrase: $(apg -m32 -n1)
EOF
chmod -v 0600 ~/.s3ql/authinfo2
```

### OpenStack client

```bash
pip3 install -U python-openstackclient
openstack --os-cloud system-backup complete > /etc/bash_completion.d/openstack
mkdir -p ~/.config/openstack
cat > ~/.config/openstack/clouds.yaml <<EOF
clouds:
  ${CLOUD_NAME}:
    auth:
      auth_url: ${OS_AUTH_URL}
      project_name: ${OS_TENANT_NAME}
      username: ${OS_USERNAME}
      password: ${OS_PASSWORD}
    region_name: ${OS_REGION_NAME}
EOF
openstack --os-cloud ${CLOUD_NAME} container list
openstack --os-cloud ${CLOUD_NAME} object list ${CONTAINER_NAME}
```

### Tested object storage providers

- [**Amazon S3**](https://aws.amazon.com/s3/)
- [**Backblaze B2**](https://www.backblaze.com/b2/cloud-storage.html)
- [**Selectel Cloud Storage**](https://selectel.com/services/cloud/storage/)
- [**Oktawave OCS**](https://www.oktawave.com/en/storage)
- [Google Cloud Storage](https://cloud.google.com/storage/)
- [Cloudwatt by Orange](https://www.cloudwatt.com/en/products.html)
- [Brightbox Orbit](https://www.brightbox.com/cloud/storage/)
- [OVH Public Cloud Object Storage](https://docs.ovh.com/pages/releaseview.action?pageId=18121668)
- [hubiC object storage by OVH](https://hubic.com/en/offers/) `communication failures!`
- https://www.exoscale.ch/object-storage/
- https://www.profitbricks.de/
- https://auro.io/public_cloud_hosting/product
- https://www.pcextreme.com/aurora/objects
- https://zetta.io/en/products/object-storage/
- https://www.e24cloud.com/en/cloud-features/files-in-the-cloud/
- https://dunkel.de/s3
- https://www.citycloud.com/features/full-feature-list/
- https://advania.com/products-and-services/cloud-marketplace/

Lists

- https://cloudharmony.com/cloudsquare/cloud-storage-in-eu
- http://gaul.org/object-store-comparison/

### Servers with large disks

With [minio](https://minio.io/) installed as S3 compatible object storage server.

- [Contabo VPS M](https://contabo.com/?show=vps) 500 GB €7/m
- [OVH/KS-1 server](https://www.kimsufi.com/en/) 500 GB €5/m
- [HostHatch Storage VPS](https://hosthatch.com/storage-vps) 250 GB €5/m

### mega.co.nz CLI

https://packages.debian.org/unstable/megatools
