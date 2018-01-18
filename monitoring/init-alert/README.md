# Send alert mail on system boot and on shutdown

https://www.debian.org/doc/manuals/maint-guide/dother.en.html

```bash
shellcheck debian/init-alert.init
dpkg-buildpackage -uc -us
debuild clean
lintian --display-info --display-experimental --pedantic ../init-alert_*_all.deb
```

### Remove previous implementation

```bash
insserv --remove boot-alert
insserv --remove halt-alert
rm -f /etc/init.d/boot-alert /etc/init.d/halt-alert
```
