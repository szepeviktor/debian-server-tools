# Courier MTA


| Receive                                  |       |                                Deliver |
| ---------------------------------------- | :---: | -------------------------------------: |
| Inbound: foreign, satellite, authenticated |     | Outbound: foreign, smarthost, provider |
| Local: sendmail/TCP, DSN       | **Courier MTA** |                                Mailbox |
| Fetchmail: remote mailbox      |      IMAP       |                    SRS: remote mailbox |


### Message processing order on reception

1. SMTP communication
1. `NOADD*=`, `opt MIME=none`
1. filters
1. `DEFAULTDELIVERY=`

### SSL settings

**Courier seems to support only `DHE-*` over `TLSv1.2`.**

Many mail servers (with OpenSSL before version 1.0.1) support only TLSv1, even older systems only SSL3.

- Inbound foreign: Mozilla SSL Intermediate
- Inbound satellite and authenticated: Mozilla SSL **Modern**
- [Fetchmail](http://www.fetchmail.info/fetchmail-man.html#8): Mozilla SSL **Modern**
- Outbound foreign: Mozilla SSL Intermediate
- Outbound smarthost and provider: Mozilla SSL **Modern**
- IMAP: Mozilla SSL **Modern**


### Inbound (foreign)

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

### Inbound

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

### Delivering

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
