### Test filter regexp

```bash
echo "<LOG_LINE>" > log

wget https://github.com/fail2ban/fail2ban/raw/master/config/filter.d/apache-common.conf
fail2ban-regex $(pwd)/log $(pwd)/apache-combined.local
rm apache-common.conf
```
