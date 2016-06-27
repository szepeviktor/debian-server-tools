# Dangerous IP ranges

Use `ipset-install.sh`

### Usage on systems without ipset

```bash
grep -h "^add" *.ipset | cut -d " " -f 3 | sortip \
    | xargs -L 1 echo iptables -I myattackers -j REJECT -s
```
