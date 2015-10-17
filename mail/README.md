### Marketing tools

https://www.getdrip.com/features


### Outlook 2013

- Root: "Inbox"
- To recognize standard folder names [delete .pst/.ost file](http://answers.microsoft.com/en-us/office/forum/office_2013_release-outlook/outlook-2013-with-imap-deleted-items-and-trash-i/9ec6e501-8e1a-45cf-bb90-cb9e2205d025)
after account setup
- Fix folder subscription, see: ${D}/mail/courier-outlook-subscribe-bug.sh (Outlook 2007)

### MacOS Mail.app

Advanced/IMAP Path Prefix: "INBOX"

### Set up Google Apps mailing

https://toolbox.googleapps.com/apps/checkmx/

### Disposable email address

http://nincsmail.hu/ (inbox and sending)

### Transactional email providers

- https://aws.amazon.com/ses/
- https://www.mandrill.com/
- https://sendgrid.com/
- https://www.mailgun.com/
- https://postmarkapp.com/
- https://www.sendinblue.com/
- https://www.mailjet.com/
- https://www.campaignmonitor.com/

### Open winmail.dat

https://github.com/Yeraze/ytnef

See: ${D}/repo/debian/pool/main/y/ytnef/

MIME type: application/ms-tnef

### Mail account migration

- see: mail/imapsync
- [OVH ImapCopy](https://ssl0.ovh.net/ie/imapcopy/)
- [OfflineIMAP](https://github.com/OfflineIMAP/offlineimap)

### Send all messages in an mbox file to an email address

See: ${D}/mail/mbox_send2.py

### IMAP PLAIN authentication

```imap
D0 CAPABILITY
D1 AUTHENTICATE PLAIN
$(echo -en "\0USERNAME\0PASSWORD" | base64)
D2 LOGOUT
```

### Email forwarding (srs)

Build Courier SRS

```bash
apt-get install -y build-essential libsrs2-dev libpopt0
git clone https://github.com/szepeviktor/couriersrs
cd couriersrs
./configure --sysconfdir=/etc
make
make install
```

See `couriersrs` package: http://szepeviktor.github.io/

Set up SRS secret

```bash
./couriersrs -v
apg -a 1 -M LCNS -m 30 -n 1 > /etc/srs_secret
chown root:daemon /etc/srs_secret
chmod 640 /etc/srs_secret
```

Create system aliases `SRS0` and `SRS1`.

```bash
echo "|/usr/bin/couriersrs --reverse" > /etc/courier/aliasdir/.courier-SRS0-default
echo "|/usr/bin/couriersrs --reverse" > /etc/courier/aliasdir/.courier-SRS1-default
```

Add forwarding alias

`user:  |/usr/bin/couriersrs --srsdomain=domain.srs username@external-domain.net`

\* Note: SRS domain cannot be a virtual domain (`@virt.dom: an@account.net`).

### Courier catchall address

http://www.courier-mta.org/makehosteddomains.html

http://www.courier-mta.org/dot-courier.html

Add alias: `@target.tld:  foo`

Delivery instructions:

```bash
echo "|/pipe/command" > /var/mail/localhost/user/.courier-foo-default
```

### Courier kitchen sink (drop incoming messages)

See the description of `/etc/courier/aliasdir` in `man dot-courier` DELIVERY INSTRUCTIONS

`echo "" > /etc/courier/aliasdir/.courier-kitchensink`

Add alias: `ANY.ADDRESS@ANY.DOMAIN.TLD:  kitchensink@localhost`

### Spamassassin test and email authentication

```bash
sudo -u daemon -- spamassassin --test-mode -D < msg.eml

# For specific tests see: man spamassassin-run
sudo -u daemon -- spamassassin --test-mode -D dkim < msg-signed.eml

opendkim -vvv -t msg-signed.eml
```

#### Sender ID (From:)

- http://en.wikipedia.org/wiki/Sender_ID
- http://tools.ietf.org/html/rfc4407#section-2
- PRA: Resent-Sender > Resent-From > Sender > From > ill-formed
- http://www.appmaildev.com/

#### SPF (HELO, MAIL FROM:)

- setup http://www.spfwizard.net/
- check http://www.kitterman.com/spf/validate.html
- monitor `host -t TXT <domain>; pyspf`

#### DKIM

- [RFC 6376](https://tools.ietf.org/html/rfc6376)
- setup http://www.tana.it/sw/zdkimfilter/
- check
- monitor

##### DKIM tests

- sa-test@sendmail.net
- check-auth@verifier.port25.com
- autorespond+dkim@dk.elandsys.com
- test@dkimtest.jason.long.name
- dktest@exhalus.net
- dkim-test@altn.com
- dktest@blackops.org
- http://www.brandonchecketts.com/emailtest.php
- http://www.appmaildev.com/en/dkim/
- http://9vx.org/~dho/dkim_validate.php

#### ADSP

An optional extension to the DKIM E-mail authentication scheme.

https://unlocktheinbox.com/resources/adsp/

#### Domain Keys

Deprecated.

#### SenderID

?

#### DMARC

Specs: https://datatracker.ietf.org/doc/draft-kucherawy-dmarc-base/?include_text=1

- setup https://unlocktheinbox.com/dmarcwizard/
- check
- monitor `host -t TXT <domain>`

http://www.returnpath.com/solution-content/dmarc-support/what-is-dmarc/

#### Bulk mail

##### Body parts

- Descriptive From name "Firstname from Company"
- Descriptive subject line
- Short preview line at top of the message
- Link to online version (newsletter archive)
- Short main header line
- Subheader lines
- Sections: image + title + description + call2action  https://litmus.com/subscribe

##### Footer

- Sender's contact details (postal address, phone number)
- Who (name, email address, why) is subscribed
- Unsubscribe link

##### Email headers

- List-Unsubscribe: URL (invisible)
- Precedence: bulk (invisible)
- Return-Path: bounce@addre.ss (invisible)
- Reply-to: reply@addre.ss (invisible)
- From: sender@domain.net
- To: recipients@addre.ss
- X-Autoreply: yes
- Auto-Submitted: auto-replied

##### Others

- SMTP `MAIL FORM: <user@domain.net>`
- HTML and plain payload
- From address SPF `include:servers.mcsv.net`
- [Bulk Senders Guidelines by Google](https://support.google.com/mail/answer/81126)

##### Feedback loop

https://wordtothewise.com/isp-information/

### Email templates

- https://litmus.com/blog/go-responsive-with-these-7-free-email-templates-from-stamplia
- https://www.klaviyo.com/
- https://litmus.com/subscribe

### Email tests

- https://www.mail-tester.com/ by Mailpoet
- http://spamcheck.postmarkapp.com/
- mailtest@unlocktheinbox.com https://www.unlocktheinbox.com/bulkemailvalidator/
- checkmyauth@auth.returnpath.net
- https://winning.email/checkup/DOMAIN

### White lists

- https://www.dnswl.org/?page_id=87
- .

### RBL-s (DNSBL)

##### List of blacklists

- https://mxtoolbox.com/problem/blacklist/
- http://www.dnsbl-check.info/
- http://bgp.he.net/ip/1.2.3.4#_rbl

##### Anti-abuse's list: http://www.anti-abuse.org/

```
bl.spamcop.net
cbl.abuseat.org
b.barracudacentral.org
dnsbl.sorbs.net
http.dnsbl.sorbs.net
dul.dnsbl.sorbs.net
misc.dnsbl.sorbs.net
smtp.dnsbl.sorbs.net
socks.dnsbl.sorbs.net
spam.dnsbl.sorbs.net
web.dnsbl.sorbs.net
zombie.dnsbl.sorbs.net
dnsbl-1.uceprotect.net
dnsbl-2.uceprotect.net
dnsbl-3.uceprotect.net
pbl.spamhaus.org
sbl.spamhaus.org
xbl.spamhaus.org
zen.spamhaus.org
bl.spamcannibal.org
psbl.surriel.com
ubl.unsubscore.com
rbl.spamlab.com
dyna.spamrats.com
noptr.spamrats.com
spam.spamrats.com
cbl.anti-spam.org.cn
cdl.anti-spam.org.cn
dnsbl.inps.de
drone.abuse.ch
httpbl.abuse.ch
korea.services.net
short.rbl.jp
virus.rbl.jp
spamrbl.imp.ch
wormrbl.imp.ch
virbl.bit.nl
rbl.suresupport.com
dsn.rfc-ignorant.org
ips.backscatterer.org
spamguard.leadmon.net
opm.tornevall.org
multi.surbl.org
ix.dnsbl.manitu.net
tor.dan.me.uk
rbl.efnetrbl.org
dnsbl.dronebl.org
access.redhawk.org
db.wpbl.info
rbl.interserver.net
query.senderbase.org
bogons.cymru.com
csi.cloudmark.com
```

##### Check RBL-s

`cat anti-abuse.org.rbl|xargs -I%% host -tA $(revip "$IP").%% 2>&1|grep -v "not found: 3(NXDOMAIN)"`

##### Trendmicro ERS

`wget -qO- --post-data="_method=POST&data[Reputation][ip]=${IP}" https://ers.trendmicro.com/reputations \
    | sed -n 's;.*<dd>\(.\+\)</dd>.*;\1;p' | tr '\n' ' '`

Response: "IP Unlisted in the spam sender list None"

### Monitoring you server's IP reputation

- https://www.rblmon.com/accounts/register/
- https://www.projecthoneypot.org/monitor_settings.php
- 