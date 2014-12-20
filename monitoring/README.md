### Error searching in a log file

```bash
egrep -i -B 1 -A 1 "crit|err|warn|fail|unkn|miss|except|disable" /var/log/dmesg | grep -vi "intERRupt"

egrep -i "crit|err|warn|fail|unkn|miss|except|disable" /var/log/syslog
```
