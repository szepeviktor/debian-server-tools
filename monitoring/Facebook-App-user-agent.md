# Facebook App user agent decoding

Both for iOS and Android.

```
FBAN Application Name
FBAV Application Version
FBBV Build Version
FBDV Device Version
FBMD Major Device
FBSN System Name
FBSV System Version
FBSS System Sub-version ???
FBCR CarrieR
FBID Identity of Device
FBLC Locale
FBOP Other Parameters ???
FBRV Revision
FBDM DisplayMetrics
```

Filter webserver logs:

```bash
grep -o ' \[FB[^]]\+\]' | sed -e 's/;FB/\n  FB/g' -e 's/\]/]\n/'
```

[Source](https://www.webmasterworld.com/search_engine_spiders/4729148.htm#collapseMSG3005706)
