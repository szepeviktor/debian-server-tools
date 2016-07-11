### Test filter regexp

```bash
echo "LOG-LINE" > log

wget -nv https://github.com/fail2ban/fail2ban/raw/master/config/filter.d/apache-common.conf
fail2ban-regex --print-all-matched $(pwd)/log $(pwd)/apache-combined.local
rm -f apache-common.conf log
```
