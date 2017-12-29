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

Packages dependencies should be placed in the mounted volume, by default `/opt/results`

#### Hook example

Download a tar.gz file of a Debian package.

Enter the URL in `--env PACKAGE="$URL"`

`/opt/results/debackport-source`

```bash
wget -qO- "$PACKAGE" | tar -xz
# We hope it contains one directory
cd *
CHANGELOG_MSG="Built from tar: ${PACKAGE}"
```

### Backport Apache httpd

- spdylay/testing
- nghttp2/testing
- apr-util/testing
- apache2/testing
