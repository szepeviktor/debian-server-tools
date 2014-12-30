### Error searching in a log file

```bash
egrep -i -B 1 -A 1 "crit|err|warn|fail[^2]|unkn|miss|except|disable|invalid|cannot|denied" /var/log/dmesg | grep -vi "intERRupt"

egrep -i "crit|err|warn|fail[^2]|unkn|miss|except|disable|invalid|cannot|denied" /var/log/syslog | grep -vi "intERRupt"
```
