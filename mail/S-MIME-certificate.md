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
