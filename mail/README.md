# Mail servers

### E-mail server factors

- Transport encryption (TLS on SMTP in&out and IMAP)
- Forwarding with SRS (Sender Rewriting Scheme)
- [Fetch instead of forwarding](http://scribu.net/blog/properly-forwarding-email-to-gmail.html)
- Attack mitigation (SMTP vulnerability, authentication)
- Spam filtering
- Custom blackhole lists (RBL)
- Custom whitelisting of hosts (broken mail servers)
- Monitor IP reputation
- Apply to whitelists
- Register to feedback loops
- Monitor delivery and delivery errors

### Transactional email providers

- https://aws.amazon.com/ses/ by Amazon *free:0*
- https://www.sparkpost.com/ on AWS *free:15 000*
- https://www.mandrill.com/ by MailChimp *free:0*
- https://www.sendinblue.com/ has own AS *free:9000*
- [M<sup>3</sup>AAWG members](https://www.m3aawg.org/about/roster)

* https://sendgrid.com/ has own AS *free:3000*
* https://www.mailgun.com/ by Rackspace *free:10 000*
* https://www.mailjet.com/transactional *free:6000*
* https://postmarkapp.com/ by Wildbit *free:1×25 000*

[Integrity Mailszolgáltatás (SMTP+IMAP)](https://integrity.hu/mailszolgaltatas/)

#### Email delivery features

- Shared IP / IP pool / Dedicated IP
- On whitelists (mailspike, dnswl.org, Return Path)
- Open tracking (custom domain?, HTTPS?)
- Click tracking (custom domain?, HTTPS?)
- Bounce handling ([SMTP bounce classification](https://github.com/phantasm66/smtp-bounce-classifer/blob/master/README.md#the-classifier))

### Marketing tools

- https://www.getdrip.com/features
- https://www.campaignmonitor.com/

### Webmail

- https://www.horde.org/
- https://www.rainloop.net/changelog/


## Problems


### Outlook 2013 IMAP fixes

- Root: "Inbox"
- To recognize standard folder names [delete .pst/.ost file](http://answers.microsoft.com/en-us/office/forum/office_2013_release-outlook/outlook-2013-with-imap-deleted-items-and-trash-i/9ec6e501-8e1a-45cf-bb90-cb9e2205d025)
after account setup
- Fix folder subscription, see /mail/courier-outlook-subscribe-bug.sh (Outlook 2007)

### MacOS Mail.app IMAP fixes

Advanced/IMAP Path Prefix: "INBOX"

### Open winmail.dat

https://github.com/Yeraze/ytnef

See /repo/debian/pool/main/y/ytnef/

MIME type: `application/ms-tnef`

### Set up Google Apps mailing

https://toolbox.googleapps.com/apps/checkmx/

### Online IMAP migration

- [imapsync](https://github.com/imapsync/imapsync)
- [OVH ImapCopy](https://ssl0.ovh.net/ie/imapcopy/)
- [OfflineIMAP](https://github.com/OfflineIMAP/offlineimap)

### Email filters

- https://www.mailscanner.info/install/
- https://wiki.efa-project.org/

### Decode emails

- Encoded (base64 or QP) headers: `conv2047.pl -d`
- Body and attachments: `munpack -t`
- Syntax highlight: `headers.vim` for vim, `/input/mc/email.syntax` for mcedit
- Enveloped-data (application/pkcs7-mime): `cat smime.p7m | base64 -d | openssl smime -verify -inform DER`


## Settings


### Malware (virus) scanning

- ClamAV (CCTTS, Safe Browsing)
- clamav-unofficial-sigs (paid: SecuriteInfo, MalwarePatrol, free: Sanesecurity)
- `clamav.py` pythonfilter through pyClamd for Courier MTA

clamav-unofficial-sigs needs 1 GB of memory.

See "Best clamd.conf" in [SecuriteInfo](https://www.securiteinfo.com/services/anti-spam-anti-virus/improve-detection-rate-of-zero-day-malwares-for-clamav.shtml) FAQ.

### Block executables

courier-pythonfilter `attachments` module

```ini
[attachments.py]
blockedPattern = r'^.*\.(ade|adp|bat|chm|cmd|com|cpl|dll|exe|hta|inf|ins|isp|jar|js|jse|lib|lnk|mde|msc|msp|mst|pif|reg|scf|scr|sct|shb|shs|sys|url|xxe|vb|vbe|vbs|vxd|wsc|wsf|wsh)$'
```

### GMail's blocked file types

https://support.google.com/mail/answer/6590

[Spamassassin rule](https://spamassassin.apache.org/full/3.4.x/doc/Mail_SpamAssassin_Plugin_MIMEHeader.html)

`20_gmail-blocked-filetypes.cf`

```
# GMail's blocked file types
ifplugin Mail::SpamAssassin::Plugin::MIMEHeader

mimeheader GMAIL_BLOCKED_ATTACH Content-Type =~ /\.(ADE|ADP|BAT|CHM|CMD|COM|CPL|EXE|HTA|INS|ISP|JAR|JSE|LIB|LNK|MDE|MSC|MSP|MST|PIF|SCR|SCT|SHB|SYS|VB|VBE|VBS|VXD|WSC|WSF|WSH)/i
mimeheader GMAIL_BLOCKED_ATTACH_CD Content-Disposition =~ /\.(ADE|ADP|BAT|CHM|CMD|COM|CPL|EXE|HTA|INS|ISP|JAR|JSE|LIB|LNK|MDE|MSC|MSP|MST|PIF|SCR|SCT|SHB|SYS|VB|VBE|VBS|VXD|WSC|WSF|WSH)/i
score GMAIL_BLOCKED_ATTACH 20
score GMAIL_BLOCKED_ATTACH_CD 20

endif
```

### Send all messages in an mbox file to an email address

See [mbox_send2.py](./mbox_send2.py)

### Email forwarding (srs)

Build Courier SRS

See /package/couriersrs-jessie.sh

### Courier catchall address

http://www.courier-mta.org/makehosteddomains.html

http://www.courier-mta.org/dot-courier.html

Add alias:

```
@target.tld:  foo
```

Delivery instructions:

```bash
echo "|/pipe/command" > /var/mail/domain/user/.courier-foo-default
```

### Spamtrap

```
spamtrap@domain.net:  |/usr/local/bin/multi-stdout.sh "/usr/bin/spamc -4 --learntype=spam --max-size=1048576" "/usr/bin/spamc -4 --reporttype=report --max-size=1048576"
problematic@address.es:  spamtrap@domain.net
```

### NAIH nyilvántartási szám - "Hungarian National Authority for Data Protection and Freedom of Information" registry

[NAIH kereső](http://81.183.229.204:8080/EMS/EMSDataProtectionRequest/Finder)
http://www.naih.hu/kereses-az-adatvedelmi-nyilvantartasban.html

### Courier MTA message processing order on reception

1. SMTP communication
1. NOADD*, `opt MIME=none`
1. filters
1. DEFAULTDELIVERY

### Courier kitchen sink (drop incoming messages)

See the description of `/etc/courier/aliasdir` in `man dot-courier` DELIVERY INSTRUCTIONS

```bash
echo > /etc/courier/aliasdir/.courier-kitchensink
```

Add alias:

```
ANY.ADDRESS@ANY.DOMAIN.TLD:  kitchensink@localhost
```

### Courier MTA log analyzer

[Courier-analog](http://www.courier-mta.org/download.html#analog)

### Courier as smarthost client

`esmtproutes` "both MX and A records get looked up"

### Non-email domains

[Tarbaby](http://wiki.junkemailfilter.com/index.php/Project_tarbaby#Using_Tarbaby_with_Dead_Domains)


## Test


### IMAP PLAIN authentication

```imap
D0 CAPABILITY
D1 AUTHENTICATE PLAIN
$(echo -en "\0USERNAME\0PASSWORD" | base64)
D2 LOGOUT
```

### Spamassassin test and email authentication

```bash
sudo -u daemon -- spamassassin --test-mode --prefspath=/var/mail/.spamassassin/user_prefs -D < msg.eml

# For specific tests issue
#     man spamassassin-run
sudo -u daemon -- spamassassin --test-mode --prefspath=/var/mail/.spamassassin/user_prefs -D dkim < msg-signed.eml

opendkim -vvv -t msg-signed.eml
```

### Mailserver SSL test

Forwarding a temporary server's tcp/443 to Courier's tcp/465.

```bash
read -p "Courier IP? " COURIER_IP
read -p "This host's IP? " TEMPORARY_VPS_IP
sysctl --write net.ipv4.conf.all.route_localnet=1
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination ${COURIER_IP}:465
iptables -t nat -A POSTROUTING -p tcp --dst ${COURIER_IP} --dport 465 -j SNAT --to-source ${TEMPORARY_VPS_IP}
```

Then browse to https://www.ssllabs.com/ssltest/

See also https://ssl-tools.net/ and https://discovery.cryptosense.com/

### E-mail authentication

- https://www.unlocktheinbox.com/resources/identifieralignments/
- http://www.openspf.org/Related_Solutions

#### SPF (HELO, MAIL FROM:)

- setup https://tools.sparkpost.com/spf/builder http://www.spfwizard.net/
- check https://dmarcian.com/spf-survey/ http://tools.wordtothewise.com/authentication
- monitor `host -t TXT <domain>; pyspf`
- For non-email domains: `v=spf1 -all`

#### DKIM

- [RFC 6376](https://tools.ietf.org/html/rfc6376)
- setup http://www.tana.it/sw/zdkimfilter/
- check
- monitor

##### DKIM tests

- check-auth@verifier.port25.com
- autorespond+dkim@dk.elandsys.com
- test@dkimtest.jason.long.name
- dktest@exhalus.net
- dkim-test@altn.com
- dktest@blackops.org
- http://dkimvalidator.com/
- http://www.appmaildev.com/en/dkim/
- http://9vx.org/~dho/dkim_validate.php
- https://protodave.com/tools/dkim-key-checker/ (DNS only)

#### DMARC

Specs: https://datatracker.ietf.org/doc/rfc7489/

- setup http://www.kitterman.com/dmarc/assistant.html
- check https://dmarcian.com/dmarc-inspector/
- monitor `host -t TXT _dmarc.example.com` https://www.dmarcanalyzer.com/
- empty record: `v=DMARC1; p=none`
- permissive record: `v=DMARC1; p=none; rua=mailto:admin@szepe.net; ruf=mailto:admin@szepe.net; fo=1`

https://blog.returnpath.com/how-to-explain-dmarc-in-plain-english/

External destination verification: https://space.dmarcian.com/what-is-external-destination-verification/

#### ADSP

Declared "Historic".

An optional extension to the DKIM E-mail authentication scheme.

https://unlocktheinbox.com/resources/adsp/

#### Sender ID from Microsoft (From:)

- http://en.wikipedia.org/wiki/Sender_ID
- http://tools.ietf.org/html/rfc4407#section-2
- PRA: Resent-Sender > Resent-From > Sender > From > ill-formed
- http://www.appmaildev.com/

#### Domain Keys

Deprecated.

### Bulk mail

#### Headers and Body parts

- :sunny: :sunny: :sunny: Descriptive From name "Firstname from Company"
- :sunny: :sunny: Descriptive subject line
- :sunny: Short [preview text](https://litmus.com/blog/the-ultimate-guide-to-preview-text-support) at top of the message
- Link to online version (newsletter archive)
- Company logo
- Short main header
- :bulb: Sections: image + title + description + call2action + background color, see https://litmus.com/subscribe
- External resources should be able to load through HTTPS (opening in a HTTPS webmail)
- :iphone: Mobile compatible

#### Footer

- Sender's contact details (postal address, phone number)
- Who (recipient name, email address, why) is subscribed
- Unsubscribe link
- [Forward to a friend](/mail/forward-to-a-friend.png)
- [NAIH nyilvántartási szám](https://www.naih.hu/bejelentkezes.html)

#### Email headers

- `From: sender@example.com`
- `Reply-to: reply@example.com` (invisible) [How to video](https://youtu.be/mGSPj4CyOMQ?t=1m20s)
- `To: recipients@addre.ss`
- `Precedence: bulk` (invisible)
- `List-Unsubscribe: URL` (invisible)
- `Return-Path: bounce@example.com` (invisible)
- bounce `X-Autoreply: yes`
- bounce `Auto-Submitted: auto-replied`

#### Others

- **When to send a newsletter?**
- HTML and plain text payload
- [Bulk Senders Guidelines by Google](https://support.google.com/mail/answer/81126)
- [Spamhaus Marketing FAQ](https://www.spamhaus.org/faq/section/Marketing%20FAQs)
- [Rackspace Postmaster](https://postmaster.emailsrvr.com/sending-to-us)
- :cloud: CDN for images
- SMTP `MAIL FORM: <user@example.com>`
- SMTP Envelope sender SPF `include:servers.mcsv.net`

### Email templates

- https://litmus.com/community/templates
- https://litmus.com/blog/go-responsive-with-these-7-free-email-templates-from-stamplia
- https://litmus.com/subscribe

### Email design

- https://www.klaviyo.com/
- https://mailchimp.com/
- https://wireframe.cc/

### Email tests

- https://www.mail-tester.com/ by Mailpoet
- https://glockapps.com/
- http://spamcheck.postmarkapp.com/
- mailtest@unlocktheinbox.com https://www.unlocktheinbox.com/resources/emailauthentication/
- checkmyauth@auth.returnpath.net
- https://winning.email/checkup/DOMAIN

#### HTML content and CSS inlining

- https://inlinestyler.torchbox.com/styler/
- https://putsmail.com/

### Providers

- https://tinyletter.com/
- https://www.klaviyo.com/
- https://mailchimp.com/
- viktor@szepe.net (€6/1000 emails)

## Deliverability


### RBL-s (DNSBL)

- [List of blacklists](http://www.intra2net.com/en/support/antispam/index.php)
- [Whitelists in SpamAssassin](https://wiki.apache.org/spamassassin/DnsBlocklists#Whitelists)
- [Sender Support and Delivery and Filtering Details](https://wordtothewise.com/isp-information/)


#### Check RBL-s

```bash
rblcheck
```

Courier MTA

```ini
BLACKLISTS="-block=bl.blocklist.de"
```

Trendmicro ERS check

```bash
wget -qO- --post-data="_method=POST&data[Reputation][ip]=${IP}" https://ers.trendmicro.com/reputations \
    | sed -ne 's;.*<dd>\(.\+\)</dd>.*;\1;p' | tr '\n' ' '
```

OK response: `IP Unlisted in the spam sender list None`


### Mail server reputation

`R` - Register your mail server here

#### ESP Postmaster Site/Feedback loop (FBL)

- [Google Postmaster Tools](https://postmaster.google.com/) `R` [Gmail Spam FBL](https://www.sparkpost.com/blog/all-you-need-to-know-about-gmail-feedback-loop-offering/)
- [Yahoo! Postmaster](https://help.yahoo.com/kb/postmaster) `R`
- [Outlook.com by Microsoft](https://mail.live.com/mail/services.aspx) `R` [Smart Network Data Service (SNDS)](https://postmaster.live.com/snds/) [Junk Email Reporting Program (JMRP)](https://postmaster.live.com/snds/JMRP.aspx)
- [AOL Postmaster](https://postmaster.aol.com/whitelist-request) `R` [IP reputation](https://postmaster.aol.com/ip-reputation)
- [Yandex Postmaster](https://postoffice.yandex.com/) `R` [Feedback Loop](http://yandexfbl.senderscore.net/)
- [mail.ru Postmaster](https://postmaster.mail.ru/)
- https://poczta.onet.pl/pomoc/en,odblokuj.html
- http://wiki.wordtothewise.com/ISP_Summary_Information (list)

#### ESP Sender Support/Delivery Issues

- https://support.google.com/mail/contact/msgdelivery
- https://support.google.com/mail/contact/bulk_send_new
- [Sender Information for Outlook.com Delivery](https://go.microsoft.com/fwlink/?LinkID=614866)

#### ESP Abuse Reporting

- [Report abuse from Gmail](https://support.google.com/mail/contact/abuse)
- [Report abuse from Outlook.com](mailto:abuse@outlook.com) See SenderScore
- [Abuse Contact DB](https://www.abusix.com/contactdb) `host -t TXT $(revip $IP).abuse-contacts.abusix.org` (list)

#### Whitelists

- https://www.dnswl.org/selfservice/ `R`
- ??? [EmailReg.org by Barracuda](http://www.emailreg.org/index.cgi?p=usage)
- ??? [Whitelisted.org by UCEPROTECT](http://www.whitelisted.org/)

#### Blacklists (RBL, DNSBL)

- http://www.projecthoneypot.org/search_ip.php `R`
- http://psky.me/
- http://blacklist.lashback.com/
- https://rbl.foobar.hu/

#### Certification Services/IP Reputation

- https://www.senderscore.org/lookup.php by ReturnPath
- https://www.ers.trendmicro.com/reputations/legitimate `R`
- http://www.barracudacentral.org/lookups
- http://www.cyren.com/ip-reputation-check.html
- http://www.mcafee.com/threat-intelligence/ip/spam-senders.aspx [lookup](http://www.mcafee.com/threat-intelligence/ip/default.aspx?ip=1.2.3.4)
- http://ipremoval.sms.symantec.com/lookup/

#### Threat Centers

- https://www.talosintelligence.com/reputation_center by Cisco
- [AlienVault](https://otx.alienvault.com/browse/pulses/)
- https://www.mcafee.com/uk/threat-center.aspx
- [Facebook ThreatExchange](https://developers.facebook.com/products/threat-exchange)
- [Open Threat Intelligence](https://cymon.io/)
- List of Data Sources: https://github.com/HurricaneLabs/machinae

#### Lookup Tools/Monitoring Tools

- https://glockapps.com/spam-testing `R`
- http://bgp.he.net/ip/1.2.3.4#_rbl
- https://hetrixtools.com/dashboard/blacklist-monitors/
- http://multirbl.valli.org/
- https://mxtoolbox.com/problem/blacklist/ [chart](https://mxtoolbox.com/Public/ChartHandler.aspx?type=TopBlacklistActivity)
- https://rbltracker.com/ `R`
- https://www.rblmon.com/accounts/register/ `R`

### Free e-mail backup server

http://www.junkemailfilter.com/spam/free_mx_backup_service.html
