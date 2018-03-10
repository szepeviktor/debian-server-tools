# Courier MTA


| Receive                                    | :gear:  |                                Deliver |
| ------------------------------------------ | :-----: | -------------------------------------: |
| Inbound: foreign, satellite, authenticated | filters | Outbound: foreign, smarthost, provider |
| Local: sendmail/TCP, DSN           | **Courier MTA** |                                Mailbox |
| Fetchmail: remote mailbox          |      IMAP       |                    SRS: remote mailbox |


### Message processing order on reception

1. SMTP communication
1. `NOADD*=`
1. Filters
1. `DEFAULTDELIVERY=`

### SSL settings

Courier support `ECDHE-*` over `TLSv1.2` with OpenSSL from version 0.74.0 up.

Many mail servers (with OpenSSL before version 1.0.1) support only `TLSv1`, even older systems only `SSLv3`.

- Inbound foreign: Mozilla SSL Intermediate
- Inbound satellite and authenticated: Mozilla SSL **Modern**
- [Fetchmail](http://www.fetchmail.info/fetchmail-man.html#8): Mozilla SSL **Modern**
- Outbound foreign: Mozilla SSL Intermediate
- Outbound smarthost and provider: Mozilla SSL **Modern**
- IMAP: Mozilla SSL **Modern**


### Inbound (foreign)

- `bofh`
- `BLACKLISTS="-block=bl.blocklist.de"`
- Courier pythonfilter (+attachments module)
- Custom *Courier pythonfilter* modules
- Spamassassin
- ClamAV, SpamAssassin AntiVirus plugin
- BIG-mail spammers
- `spamtrap@example.com`
- Kitchen sink
- AUTH attackers, Fail2ban
- Tarbaby fake MX

### Inbound

- Incoming forwarded mail
- Aliases (system users)
- Bounce from managed servers as virtual domains
- `esmtpacceptmailfor` + `locals` or `hosteddomains` or only virtual domain
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
- DKIM ("z" DKIM filter)
- DMARC ([dmarc_shield.py](http://linode.fmp.com/contrib/dmarc_shield.py))
- Sender Rewriting Scheme (Courier SRS)

##### `esmtproutes`

- Email providers (authenticated)
- Smarthosts (authenticated)
- Safe routes (whitelisted)
- SMS gateway
- Broken STARTTLS (advertised but unavailable)
- Special cases

### Filter

- courier-pythonfilter + custom modules
- zdkimfilter

### Others

- Init scripts
- IMAP
- Fetchmail
- Horde webmail
- Monitoring, feedback loops, whitelists, RBL checkers
- SPF and DMARC
- Can-send-email
