# In-project localisation files

Adding all languages to your server's locale archive may not be desirable.

### Generating

```bash
for LOCALE in en_US hu_HU; do
    echo "${LOCALE} ..."
    localedef --replace -f UTF-8 -i "$LOCALE" "/home/user/website/locales/${LOCALE}.utf-8"
done
```

### Testing

`utf-8` with small letters.

```bash
LOCPATH="/home/user/website/locales" php -r 'var_dump( setlocale(LC_ALL, "hu_HU.utf-8") );'
```

### Environment variable

Set `LOCPATH` (libc variable) in your PHP-FPM pool configuration.

```ini
env[LOCPATH] = "/home/user/website/locales"
```
