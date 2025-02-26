# Personal Authentication Certificate

Installing an S/MIME Personal Certificate for signing emails.

- Open Microsoft Edge on Windows
- Navigate to `edge://settings/defaultBrowser`
- Allow IE mode
- Navigate to https://cheapsslsecurity.com/
- Three dot menu / Reload in IE mode
- Purchase personal certificate https://cheapsslsecurity.com/comodo/personal-authentication-certificates.html
- Open link from received verification email in Microsoft Edge
- Three dot menu / Reload in IE mode
- Wait for "Success" message
- Navigate to `edge://settings/privacy` / Security / Manage certificates
- Export certificate in PKCS #12 format (.pfx file) including the private key
- Import certificate into email client
- Delete certificate from Windows

Displaying certificate: `openssl pkcs12 -in certificate.pfx`

## Add intermediate certificate to PKCS #12

```bash
openssl pkcs12 -in pkcs12-from-Sectigo.p12 -out temp.p12 -nodes \
    -passin pass:${PASSWORD} -passout pass:${PASSWORD}
openssl pkcs12 -export -in temp.p12 -out viktor-szepe-net.pfx -certfile Sectigo-intermediate.pem \
    -passin pass:${PASSWORD} -passout pass:${PASSWORD}
rm temp.p12
```

## View PKCS #7 signature

- Copy BASE64 encoded signature from email to smime.p7s.b64
- Decode signature: `base64 -d <smime.p7s.b64 >smime.p7s`
- `openssl pkcs7 -inform DER -in smime.p7s -print_certs -text`
