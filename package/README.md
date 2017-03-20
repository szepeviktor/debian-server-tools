# Packaging related informations

### Script meta

Colon at column :16

```
#!/bin/bash
#
# One line description for this script.
#
# VERSION       :semver
# DATE          :2017-12-31
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install package
# REFS          :url
# DOCS          :url
# SOURCE        :url
# UPSTREAM      :url
# LOCATION      :/usr/local/sbin/script.sh
# OWNER         :root:root
# PERMISSION    :0755
# SYMLINK       :/usr/local/sbin/alias.sh
# CRON-HOURLY   :/usr/local/sbin/script.sh
# CRON-DAILY    :/usr/local/sbin/script.sh
# CRON-WEEKLY   :/usr/local/sbin/script.sh
# CRON-MONTHLY  :/usr/local/sbin/script.sh | mailx -E -s "subject" root
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

### debconf - Configuration management

https://www.debian.org/doc/packaging-manuals/debconf_specification.html#AEN106

### APT repository concepts

Find actual values in `debian/dists/stable/Release`

-   a,archive,suite (e.g. "stable")
-   c,component     (e.g. "main", "crontrib" or "non-free")
-   v,version       (e.g. "1.0.2-1" )
-   o,origin        (e.g. "Debian", "Unofficial Multimedia Packages")
-   l,label         (e.g. "Debian", "Debian-Security")
-   n,codename      (e.g. "jessie", "jessie-updates")
-     site          (e.g. "http.debian.net")

See apt_preferences(5) Determination of Package Version and Distribution Properties

### Inspect signing keys

```
wget -qO- KEY-URL | gpg -v --with-fingerprint
```

### Import signing keys

```
apt-key adv --keyserver pgp.mit.edu --recv-keys KEY
apt-key adv --keyserver keys.gnupg.net --recv-keys KEY
wget -qO- KEY-URL | apt-key add -
```

##### Import all signing keys for Debian contributed packages

```bash
grep -h -A 5 "^deb " /etc/apt/sources.list.d/*.list | grep "^#K: " | cut -d " " -f 2- | /bin/bash
```

### Check APT configuration

```bash
apt-config dump | pager
```

### Disable APT language

/etc/apt/apt.conf.d/00language-none

```bash
Acquire::Languages "none";
```

### Search package contents

```bash
dpkg -S FILE-PATTERN
```

### Query runlevel information for system services (init scripts)

```bash
chkconfig --list
```

### Display files sizes in a package

```bash
dpkg -L PACKAGE|while read -r F;do [ -d "$F" ]||du -sk "$F";done|sort -n
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

### Unattended cpan install

```bash
PERL_MM_USE_DEFAULT=1 cpan -i Alien::RRDtool
```

### Switch to LLVM/clang compiler

```bash
# Debian jessie
VERSION="4.9"
echo "gcc-$VERSION hold" | dpkg --set-selections
echo "cpp-$VERSION hold" | dpkg --set-selections
echo "g++-$VERSION hold" | dpkg --set-selections
cd /usr/bin/
rm -v g++-$VERSION gcc-$VERSION cpp-$VERSION
ln -vs clang++ g++-$VERSION
ln -vs clang gcc-$VERSION
ln -vs clang cpp-$VERSION
cd -
gcc --version | grep "clang"
```

### List binary files

```bash
find -type f -executable -exec file --mime "{}" ";" | grep -F "charset=binary"
```
