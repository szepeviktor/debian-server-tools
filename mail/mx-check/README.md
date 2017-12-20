# Disposable email domains

- `grep -Eixv '[a-z0-9._-]+@[a-z0-9-]+(\.[a-z]{2,5})+'`
- gmail-typo.grep
- banned-addresses.grep (user name part)
- disposable-email/*.grep (domain)
- disposable-mx.list (MX, IP)

### martenson/disposable-email-domains

```bash
wget -nv -O disposable-email-blacklist.grep https://github.com/martenson/disposable-email-domains/raw/master/disposable_email_blacklist.conf
sed -i -e 's/\./\\./g' -e 's/.*/.\\+@&/' disposable_email_blacklist.grep
```

### andreis/disposable

```bash
wget -nv -O disposable-domains.grep https://github.com/andreis/disposable/raw/master/domains.txt
sed -i -e 's/\./\\./g' -e 's/.*/.\\+@&/' disposable-domains.grep
```

### wesbos/burner-email-providers

```bash
# wget -nv -O burner-email-providers.grep https://github.com/wesbos/burner-email-providers/raw/master/emails.txt
# sed -i -e 's/\./\\./g' -e 's/.*/.\\+@&/' burner-email-providers.grep
```

### Mailinator-Domains

https://github.com/GeroldSetz/Mailinator-Domains

```bash
wget -nv https://github.com/GeroldSetz/Mailinator-Domains/raw/master/mailinator_domains_from_bdea.cc.txt
cut -d"@" -f2 addr-orig|sort -u|xargs -I% bash -c 'echo -n "%"|sha1sum -'|cut -d" " -f1 > addr-sha1
grep -Fx -f mailinator_domains_from_bdea.cc.txt addr-sha1
cut -d"@" -f2 addr-orig|sort -u|xargs -I% bash -c 'echo -n "%:";echo -n "%"|sha1sum -'|grep -F :$SHA1
```

### API

- http://www.nameapi.org/en/live-demos/disposable-email-address-detector/
- https://www.istempmail.com/check
- https://www.validator.pizza/
- https://www.block-disposable-email.com/cms/try/
