### Search for errors in a log file

```bash
grep -Ei -B 1 -A 1 "crit|err[^u]|warn|fail[^2]|alert|unknown|unable|miss|except|disable|invalid|cannot|denied|broken|exceed|unsafe|unsolicited" \
    /var/log/dmesg
grep -Ei -B 1 -A 1 "crit|err[^u]|warn|fail[^2]|alert|unknown|unable|miss|except|disable|invalid|cannot|denied|broken|exceed|unsafe|unsolicited" \
    /var/log/syslog
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

read -r -p "Host name: " DOMAIN
ls /var/lib/munin/
rm -rfI /var/lib/munin/${DOMAIN}
ls /var/cache/munin/www/
rm -rfI /var/cache/munin/www/${DOMAIN}
```

### Detect virtualization technology

- http://git.annexia.org/?p=virt-what.git;a=summary
- http://www.freedesktop.org/software/systemd/man/systemd-detect-virt.html

```bash
#apt-get install -y virt-what systemd dmidecode
virt-what
systemd-detect-virt -c; systemd-detect-virt -v
dmidecode -s system-product-name
```
