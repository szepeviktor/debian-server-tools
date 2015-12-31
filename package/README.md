# Packaging related informations

### Script meta

Colon at column :16

```
#!/bin/bash
#
# One-line description.
#
# VERSION       :semver
# DATE          :2015-12-31
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install package
# REFS          :url
# DOCS          :url
# SOURCE        :url
# UPSTREAM      :url
# LOCATION      :/usr/local/sbin/deny-ip.sh
# OWNER         :root:root
# PERMISSION    :755
# SYMLINK       :/usr/local/sbin/deny-http.sh
# CRON-HOURLY   :/usr/local/sbin/command
# CRON-DAILY    :/usr/local/bin/command
# CRON-WEEKLY   :/usr/local/bin/command
# CRON-MONTHLY  :/usr/local/sbin/script.sh | mailx -s "subject" root
# CRON.D        :2 2	* * *	root	/usr/local/sbin/script.sh
# CONFIG        :~/.config/vpscheck/configuration

# Usage/Remarks
#
# How to use, examples, remarks.
```

### APT repository concepts

-   a,archive,suite (eg, "stable")
-   c,component     (eg, "main", "crontrib", "non-free")
-   l,label         (eg, "Debian", "Debian-Security")
-   o,origin        (eg, "Debian", "Unofficial Multimedia Packages")
-   n,codename      (eg, "jessie", "jessie-updates")
-     site          (eg, "http.debian.net")

### Inspect signing keys

```
wget -qO- <KEY-URL> | gpg -v --with-fingerprint
```

### Import signing keys

```
apt-key adv --keyserver pgp.mit.edu --recv-keys <KEY>
apt-key adv --keyserver keys.gnupg.net --recv-keys <KEY>
wget -qO- <KEY-URL> | apt-key add -
```

### Unattended upgrade origins for Debian squeeze

```
Allowed origins are: ["('Debian', 'oldstable')", "('Debian', 'squeeze-security')", "('Debian', 'squeeze-lts')"]
```

##### Debian contributed

/etc/apt/sources.list.d/

```bash
# Import all signing keys
eval "$(grep -h -A5 "^deb " /etc/apt/sources.list.d/*.list | grep "^#K: " | cut -d' ' -f 2-)"
```

### Disable apt language

/etc/apt/apt.conf.d/00language-none

```bash
Acquire::Languages "none";
```

### Check apt configuration

```bash
apt-config dump | most
```

### Search package contents

```bash
dpkg -S <FILE-PATTERN>
```

### List not required and not important packages (package priority)

http://algebraicthunk.net/~dburrows/projects/aptitude/doc/en/ch02s03s05.html

```bash
aptitude search '?and(?installed, ?not(?priority(required)), ?not(?priority(important)))' -F"%p" | cut -d' ' -f 1
```

### List all installed packages and show differences from wheezy base

```bash
aptitude search '?installed' -F"%p" | cut -d' ' -f 1 > all.pkgs
grep -v -f debian-wheezy-base.pkgs all.pkgs
grep -v -f all.pkgs debian-wheezy-base.pkgs
```

### Remove development packages

```bash
aptitude search '?and(?installed, \S*-dev\b)' -F'%p' | xargs apt-get purge
```

### Query runlevel information for system services (init scripts)

```bash
chkconfig --list
```

### Install pip (Python package manager)

```bash
wget -O- https://bootstrap.pypa.io/get-pip.py | python2
wget -O- https://bootstrap.pypa.io/get-pip.py | python3
```

### Python package locations

https://wiki.debian.org/Python#Deviations_from_upstream

- Debian Python packages `/usr/lib/python3/dist-packages`
- pip (with system Python) packages `/usr/local/lib/python3.4/dist-packages`
- From-source-Python built packages `/usr/lib/python3.4/site-packages`
- ??? `/usr/local/lib/python3.4/site-packages`

```
$ find /usr -type d -name dist-packages -o -name site-packages
/usr/lib/python2.7/dist-packages
/usr/lib/python3/dist-packages
/usr/local/lib/python2.7/site-packages
/usr/local/lib/python2.7/dist-packages
/usr/local/lib/python3.4/dist-packages
```

### Convert a Python package to Debian package

```bash
apt-get install -y python-stdeb
pypi-install $PYPI_PKG
```

### Convert a PEAR package to Debian package

```bash
apt-get install -y debpear
debpear $PEAR_PKG
```

### Backporting guide

https://wiki.debian.org/BuildingFormalBackports

