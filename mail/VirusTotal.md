# VirusTotal API

```bash
curl "https://www.virustotal.com/vtapi/v2/file/report" \
    -d "apikey=1efb997dccbfa8a22399c3f9cad03e946036138cdf2ca7077b98e361d4cbb67b" \
    -d "resource=${SHA256SUM}"
```

- $json->positives
- $json->permalink
- $json->scan_date
