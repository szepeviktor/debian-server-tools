# Packaging related informations

### Script meta

Colon at column :16

```
#!/bin/bash
#
# One-line description.
#
# VERSION       :semver
# DATE          :2016-12-31
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
# CONFIG        :~/.config/script/configuration

# Usage/Remarks
#
# How to use, examples, remarks.
```

### Backporting guide

https://wiki.debian.org/BuildingFormalBackports

### dgit - git interoperability with the Debian archive

- https://packages.debian.org/testing/dgit
- http://honk.sigxcpu.org/projects/git-buildpackage/manual-html/gbp.intro.html

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

##### Import all signing keys for Debian contributed packages

```bash
grep -h -A 5 "^deb " /etc/apt/sources.list.d/*.list | grep "^#K: " | cut -d " " -f 2- | /bin/bash
```

### Check APT configuration

```bash
apt-config dump | most
```

### Disable APT language

/etc/apt/apt.conf.d/00language-none

```bash
Acquire::Languages "none";
```

### Search package contents

```bash
dpkg -S <FILE-PATTERN>
```

### List all installed packages and show differences from wheezy base

```bash
aptitude search '?installed' -F"%p" | cut -d' ' -f 1 > all.pkgs
grep -v -f debian-wheezy-base.pkgs all.pkgs
grep -v -f all.pkgs debian-wheezy-base.pkgs
```

### Query runlevel information for system services (init scripts)

```bash
chkconfig --list
```

### Display files sizes in a package

```bash
dpkg -L $PACKAGE|while read -r F;do [ -d "$F" ]||du -sk "$F";done|sort -n
```

### Display list of packages in order of package size

```bash
dpkg-query -f '${Installed-size}\t${Package}\n' --show|sort -k 1 -n
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
# find /usr -type d -name dist-packages -o -name site-packages
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

### List globally installed node packages

```bash
npm -g ls --depth=0
```

### Colorizing Debian package build output

```bash
apt-get install -y colorgcc #colormake
ln -svf /usr/bin/colorgcc /usr/local/bin/g++
ln -svf /usr/bin/colorgcc /usr/local/bin/gcc
ln -svf /usr/bin/colorgcc /usr/local/bin/cc
#ln -svf /usr/bin/colormake /usr/local/bin/make
```

### Makeself - A self-extracting archiving tool

http://stephanepeter.com/makeself/

