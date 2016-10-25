# Send alert mail on system boot and on shutdown

https://www.debian.org/doc/manuals/maint-guide/dother.en.html

```bash
shellcheck debian/init-alert.init
dpkg-buildpackage -uc -us
lintian --display-info --display-experimental --pedantic ../init-alert_*_all.deb
```
