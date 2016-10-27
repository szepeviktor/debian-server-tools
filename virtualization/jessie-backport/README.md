# Backport Debian packages

Executes a shell script that builds a Debian package in the mounted Docker volume.

### Usage

```bash
./_start.sh "http://domain.tld/path/to/package.dsc"
# Or package name and release name
./_start.sh package/testing
```

### Hooks

See hooks documented in the Bash script.

Example hook usage in `docker-backport-munin.sh`

Packages dependencies should be placed in the mounted volume, by default `/opt/results`

### Backport Apache httpd

- openssl/jessie-backports
- spdylay
- nghttp2
- apr-util
- apache2

### Backport Courier MTA

- courier-unicode
- courier-authlib
- courier
