# Courier MTA configuration checker

### GnuTLS priority string

Almost matches Mozilla SSL **Modern** profile.

```bash
#                  Ciphers                                                                Key exchange            MAC                   Compr.     TLS          Sign.     Elliptic curves                                    Certificate
TLS_PRIORITY="NONE:+CHACHA20-POLY1305:+AES-128-GCM:+AES-256-GCM:+AES-128-CBC:+AES-256-CBC:+ECDHE-ECDSA:+ECDHE-RSA:+SHA256:+SHA384:+AEAD:+COMP-NULL:+VERS-TLS1.2:+SIGN-ALL:+CURVE-SECP521R1:+CURVE-SECP384R1:+CURVE-SECP256R1:+CTYPE-X509"
```

Almost Mozilla SSL **Intermediate** profile.

```bash
#                  Ciphers                                                                          Key exchange                          MAC                         Compr.     TLS           Sign.     Elliptic curves                                    Certificate
TLS_PRIORITY="NONE:+CHACHA20-POLY1305:+AES-128-GCM:+AES-256-GCM:+AES-128-CBC:+AES-256-CBC:+3DES-CBC:+ECDHE-ECDSA:+ECDHE-RSA:+DHE-RSA:+RSA:+SHA256:+SHA384:+AEAD:+SHA1:+COMP-NULL:+VERS-TLS-ALL:+SIGN-ALL:+CURVE-SECP521R1:+CURVE-SECP384R1:+CURVE-SECP256R1:+CTYPE-X509"
```

Test: `gnutls-cli --priority="$TLS_PRIORITY" --list`

See https://www.gnutls.org/manual/gnutls.html#Priority-Strings
