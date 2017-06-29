# Courier MTA setup

### Receiving (foreign)

- SSL settings
- `bofh`
- `BLACKLISTS="-block=bl.blocklist.de"`
- Courier Python Filters (attachments)
- Custom *Courier Python Filters* modules
- Spamassassin + Pyzor
- ClamAV
- BIG-mail spammers
- spamtrap@
- Kitchen sink
- AUTH attackers, Fail2ban
- Tarbaby fake MX

### Receiving

- Incoming forwarded mail
- Aliases (system users)
- Bounce from managed servers as virtual domain
- `locals` + `esmtpacceptmailfor` + `hosteddomains`
- SMTP AUTH methods
- Accounts (userdb, `.courier` files)

##### `esmtpacceptmailfor`

1. Managed servers
2. Trusted providers
3. Broken mail servers

### Sending

- Queue and delivery settings (`queuetime`, `queuelo`, `respawnlo`, `sizelimit`)
- SSL settings
- DSN-s
- ZDKIM Filter (DKIM)
- Courier-SRS (Sender Rewriting Scheme)

##### `esmtproutes`

- Email providers (authenticated)
- Smarthosts (authenticated)
- Safe routes (whitelisted)
- SMS gateway
- Broken STARTTLS (advertised but unavailable)
- Special cases

### Others
- IMAP
- Fetchmail
- Init scripts
- Webmail (Horde)
- Monitoring, feedback loops, whitelists, RBL-s
- SPF
- Can-send-email
