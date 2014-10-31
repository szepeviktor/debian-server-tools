## Debian repository infos

-   a,archive,suite (eg, "stable")
-   c,component     (eg, "main", "crontrib", "non-free")
-   l,label         (eg, "Debian", "Debian-Security")
-   o,origin        (eg, "Debian", "Unofficial Multimedia Packages")
-   n,codename      (eg, "jessie", "jessie-updates")
-     site          (eg, "http.debian.net")

### Importing apt keys

```
apt-key adv --keyserver pgp.mit.edu --recv-keys <KEY>
```

### unattended-upgrades for squeeze

```
Allowed origins are: ["('Debian', 'oldstable')", "('Debian', 'squeeze-security')", "('Debian', 'squeeze-lts')"]
```

### Default packages sources

```bash
nano /etc/apt/sources.list
```

##### Debian official

```bash
# OVH's local mirror: http://debian.mirrors.ovh.net/debian
# server4you local mirror: http://debian.intergenia.de/debian
# closest mirror http://http.debian.net/debian
# national mirror: http://ftp.<COUNTRY-CODE>.debian.org/debian
deb http://debian.mirrors.ovh.net/debian wheezy  main contrib non-free
# security
deb http://security.debian.org/ wheezy/updates  main contrib non-free
# updates (previously known as 'volatile')
deb http://debian.mirrors.ovh.net/debian wheezy-updates  main
# backports
deb http://debian.mirrors.ovh.net/debian wheezy-backports  main
```

##### Debian contributed

```bash
# Spamassassin
deb http://ppa.launchpad.net/spamassassin/spamassassin-monthly/ubuntu natty main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys 28889276

# Tom Geißler's Apache
deb http://www.d7031.de/debian wheezy-experimental main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys DF17D0B3

# Dotdeb (is in FR)
deb http://packages.dotdeb.org/ wheezy all
deb http://packages.dotdeb.org/ wheezy-php55 all
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys 89DF5277

# MariaDB 10
deb http://mariadb.mirror.nucleus.be/repo/10.0/debian wheezy main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys 1BB943DB

# mod_pagespeed
deb http://dl.google.com/linux/mod-pagespeed/deb stable main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys 7FAC5991

# NewRelic
#deb http://apt.newrelic.com/debian newrelic non-free
# apt-key adv --keyserver pgp.mit.edu --recv-keys 548C16BF

# Glacier.pl
#deb http://dl.mt-aws.com/debian/current wheezy main
#?K:

# Multimedia
#deb http://www.deb-multimedia.org/ wheezy main non-free
#deb http://www.deb-multimedia.org/ wheezy-backports main
#K: apt-get install -y deb-multimedia-keyring

# Oracle JDK 8
#deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main
# Oracle JDK 7
#deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys EEA14886

# Percona
#deb http://repo.percona.com/apt wheezy main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys 1C4CBDCDCD2EFD2A

# PostgreSQL
#deb http://apt.postgresql.org/pub/repos/apt wheezy-pgdg main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys ACCC4CF8

# Varnish is a web application accelerator
#deb http://repo.varnish-cache.org/debian wheezy varnish-3.0

# NGINX mainline (dev)
#deb http://nginx.org/packages/mainline/debian wheezy nginx
#?K

# Modern webserver (szepe.net)
#deb http://mirror.szepe.net/debian wheezy main
#K: apt-key adv --keyserver pgp.mit.edu --recv-keys 451A4FBA

## import all signing keys ##
# eval "$(grep "^#K:" <SOURCES-FILE> | cut -d' ' -f 2-)"
```

##### Disable apt language

apt.conf.d/language-none

```bash
Acquire { Languages "none"; };
```
