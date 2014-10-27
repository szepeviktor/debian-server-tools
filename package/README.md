## Debian repository infos

-   a,archive,suite (eg, "stable")
-   c,component     (eg, "main", "crontrib", "non-free")
-   l,label         (eg, "Debian", "Debian-Security")
-   o,origin        (eg, "Debian", "Unofficial Multimedia Packages")
-   n,codename      (eg, "jessie", "jessie-updates")
-     site          (eg, "http.debian.net")

### Import apt key

apt-key adv --keyserver pgp.mit.edu --recv-keys NNNNNNNN

### unattended-upgrades for squeeze

```
Allowed origins are: ["('Debian', 'oldstable')", "('Debian', 'squeeze-security')", "('Debian', 'squeeze-lts')"]
```
