### Error searching in a log file

```bash
egrep -i -B 1 -A 1 "crit|err|warn|fail[^2]|alert|unkn|miss|except|disable|invalid|cannot|denied" /var/log/dmesg | grep -vi "intERRupt"

egrep -i "crit|err|warn|fail[^2]|alert|unkn|miss|except|disable|invalid|cannot|denied" /var/log/syslog | grep -vi "intERRupt"
```

### Courier log analyizer

```bash
courier-analogue --smtpinet --smtpitime --smtpierr --smtpos --smtpod --smtpof \
    --imapnet --imaptime --imapbyuser --imapbylength --imapbyxfer \
    --noisy --title="text" /var/log/mail.log
```

### Remove server from Munin monitoring

```bash
editor /etc/munin/munin.conf
ls /var/lib/munin/
# rm -rf /var/lib/munin/${DOMAIN}
ls /var/cache/munin/www/
# rm -rf /var/cache/munin/www/${DOMAIN}
```

### Detect VM and container

- http://git.annexia.org/?p=virt-what.git;a=summary
- http://www.freedesktop.org/software/systemd/man/systemd-detect-virt.html

`systemd-detect-virt -c; systemd-detect-virt -v`

`dmidecode -s system-product-name`
