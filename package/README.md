# Debian repository infos

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

/etc/apt/sources.list.d/other-sources.list

```bash
# Spamassassin
deb http://ppa.launchpad.net/spamassassin/spamassassin-monthly/ubuntu/ natty main
#K: apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 28889276
#M: https://launchpad.net/~spamassassin/+archive/ubuntu/spamassassin-monthly

# Tom Geißler's Apache
deb http://www.d7031.de/debian/ wheezy-experimental main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys DF17D0B3
#M: https://www.d7031.de/content/apache-24-backports-debian-wheezy-and-squeeze

# Dotdeb (is in FR)
deb http://packages.dotdeb.org/ wheezy all
deb http://packages.dotdeb.org/ wheezy-php55 all
#K: wget -qO- http://www.dotdeb.org/dotdeb.gpg | apt-key add -
#M: http://www.dotdeb.org/mirrors/

# MariaDB
deb http://mariadb.mirror.nucleus.be/repo/10.0/debian/ wheezy main
#K: apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xcbcb082a1bb943db
#M: https://downloads.mariadb.org/mariadb/repositories/#distro=Debian

# mod_pagespeed
deb http://dl.google.com/linux/mod-pagespeed/deb/ stable main
#K: wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
#M: https://developers.google.com/speed/pagespeed/module/download

# NewRelic
#deb http://apt.newrelic.com/debian/ newrelic non-free
#K: wget -qO- https://download.newrelic.com/548C16BF.gpg | apt-key add -
#M: https://docs.newrelic.com/docs/agents/php-agent/installation/php-agent-installation-ubuntu-debian

# Glacier.pl
#deb http://dl.mt-aws.com/debian/current/ wheezy main
#K: wget -qO- http://mt-aws.com/vsespb.gpg.key | apt-key add -
#M: https://github.com/vsespb/mt-aws-glacier#installation-via-os-package-manager

# Multimedia
#deb http://www.deb-multimedia.org/ wheezy main non-free
#deb http://www.deb-multimedia.org/ wheezy-backports main
#K: apt-get install -y deb-multimedia-keyring

# Oracle JDK 8
#deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main
# Oracle JDK 7
#deb http://ppa.launchpad.net/webupd8team/java/ubuntu/ precise main
#K: apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
#M: https://launchpad.net/~webupd8team/+archive/ubuntu/java

# Percona
#deb http://repo.percona.com/apt/ wheezy main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys 1C4CBDCDCD2EFD2A
#M: http://www.percona.com/doc/percona-server/5.5/installation/apt_repo.html

# PostgreSQL
#deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main
#K: wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
#M: http://www.postgresql.org/download/linux/debian/

# Varnish is a web application accelerator
#deb https://repo.varnish-cache.org/debian/ wheezy varnish-4.0
#K: wget -qO- https://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -
#M: https://www.varnish-cache.org/installation/debian

# NGINX stable
#deb http://nginx.org/packages/debian/ wheezy nginx
#K: wget -qO- http://nginx.org/keys/nginx_signing.key | apt-key add -
#M: http://nginx.org/en/linux_packages.html

# Modern webserver (szepe.net)
#deb http://szepeviktor.github.io/debian/ wheezy main
#deb http://mirror.szepe.net/debian/ wheezy main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys 451A4FBA
#M: http://mirror.szepe.net/debian/

## import all signing keys ##
# eval "$(grep "^#K:" <SOURCES-FILE> | cut -d' ' -f 2-)"
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

```bash
aptitude search '?and(?installed, ?not(?priority(required)), ?not(?priority(important)))' -F"%p" | cut -d' ' -f 1
```

### List all installed packages and show differences from wheezy base

```bash
aptitude search '?installed' -F"%p" | cut -d' ' -f 1 > all.pkgs
grep -v -f debian-wheezy-base.pkgs all.pkgs
grep -v -f all.pkgs debian-wheezy-base.pkgs
```

### Install pip (Python package manager)

```bash
wget -O- https://bootstrap.pypa.io/get-pip.py | python2
wget -O- https://bootstrap.pypa.io/get-pip.py | python3
```
