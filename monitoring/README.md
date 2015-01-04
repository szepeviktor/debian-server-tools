### Error searching in a log file

```bash
egrep -i -B 1 -A 1 "crit|err|warn|fail[^2]|alert|unkn|miss|except|disable|invalid|cannot|denied" /var/log/dmesg | grep -vi "intERRupt"

egrep -i "crit|err|warn|fail[^2]|alert|unkn|miss|except|disable|invalid|cannot|denied" /var/log/syslog | grep -vi "intERRupt"
```

### Courier log analyizer

```bash
courier-analogue --smtpinet --smtpitime --smtpierr --smtpos --smtpod --smtpof --imapnet --imaptime --imapbyuser --imapbylength --imapbyxfer --noisy --title="text" /var/log/mail.log
```
