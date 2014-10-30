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
# closest mirror http://http.debian.net/debian
# OVH's local mirror: http://debian.mirrors.ovh.net/debian
# server4you: http://debian.intergenia.de/debian
# national mirror: http://ftp.<COUNTRY-CODE>.debian.org/debian
deb <MIRROR>  wheezy  main contrib non-free
# security
deb http://security.debian.org/  wheezy/updates  main contrib non-free
# updates (previously known as 'volatile')
deb <MIRROR>  wheezy-updates  main
# backports
deb <MIRROR>  wheezy-backports  main
```

##### Debian contributed

```bash
deb ...
#K: 
deb ...
#K: 
```
