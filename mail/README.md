### Outlook 2013

- Root: "Inbox"
- To recognize standard folder names [delete .pst/.ost file](http://answers.microsoft.com/en-us/office/forum/office_2013_release-outlook/outlook-2013-with-imap-deleted-items-and-trash-i/9ec6e501-8e1a-45cf-bb90-cb9e2205d025)
after account setup
- Fix folder subscription, see: ${D}/mail/courier-outlook-subscribe-bug.sh (Outlook 2007)

### MacOS Mail.app

Advanced/IMAP Path Prefix: "INBOX"

### Open winmail.dat

https://github.com/Yeraze/ytnef

See: ${D}/repo/debian/pool/main/y/ytnef/

MIME type: application/ms-tnef

### Set up Google Apps mailing

https://toolbox.googleapps.com/apps/checkmx/

### Mail account migration

see: mail/imapsync
[OVH ImapCopy](https://ssl0.ovh.net/ie/imapcopy/)
[OfflineIMAP](https://github.com/OfflineIMAP/offlineimap)

### Send all messages in an mbox file to an email address

see: mail/mbox_send2.py

### Email sending and receiving

- SSL?
- headers: From, from name, To, Reply-to, Return-path, SMTP "MAIL FROM:"

### Courier catchall address

http://www.courier-mta.org/makehosteddomains.html
http://www.courier-mta.org/dot-courier.html

```bash
echo "|pipe/command" > /var/mail/domain.net/user/.courier-foo-default
```

### IMAP PLAIN authentication

D0 CAPABILITY
D1 AUTHENTICATE PLAIN
`echo -en "\0USERNAME\0PASSWORD" | base64`
D2 LOGOUT

### Online email tests

- https://www.mail-tester.com/
- mailtest@unlocktheinbox.com https://unlocktheinbox.com/resources/adsp/
- checkmyauth@auth.returnpath.net http://www.returnpath.com/solution-content/dmarc-support/what-is-dmarc/
- https://winning.email/checkup/<DOMAIN>

### Email forwarding (srs)

https://couriersrs.com/ https://github.com/szepeviktor/couriersrs
see: http://szepeviktor.github.io/
Create users SRS0 and SRS1.

```bash
echo "|/usr/bin/couriersrs --reverse" > /etc/courier/aliasdir/.courier-SRS0-default
echo "|/usr/bin/couriersrs --reverse" > /etc/courier/aliasdir/.courier-SRS1-default
```

### Spamassassin test and DKIM test

```bash
spamassassin --test-mode -D < msg.eml
# For specific tests see: man spamassassin-run
spamassassin --test-mode -D dkim < msg-signed.eml
opendkim -vvv -t msg-signed.eml
```

#### Sender ID (From:)

- http://en.wikipedia.org/wiki/Sender_ID
- http://tools.ietf.org/html/rfc4407#section-2
- PRA: Resent-Sender > Resent-From > Sender > From > ill-formed
- http://www.appmaildev.com/

#### SPF (HELO, MAIL FROM:)

- setup
- check
- monitor `host -t TXT <domain>`

#### DKIM

- [RFC 6376](https://tools.ietf.org/html/rfc6376)
- setup http://www.tana.it/sw/zdkimfilter/
- check
- monitor

#### ADSP

An optional extension to the DKIM E-mail authentication scheme.

#### Domain Keys

?

#### SenderID

?

#### DMARC

Specs: https://datatracker.ietf.org/doc/draft-kucherawy-dmarc-base/?include_text=1

- setup https://unlocktheinbox.com/dmarcwizard/
- check
- monitor `host -t TXT <domain>`

#### Headers

- List-Unsubscribe: <URL>
- Precedence: bulk
- Return-Path:, Reply-to:, From:, To:, Subject:
- SMTP "MAIL FORM: <from@addre.ss>"

#### Bulk mail

##### Musts

- link to online version (newsletter archive)
- who (name and email address) is subscribed
- sender's contact details (postal address, phone number)
- unsubscribe link
- HTML and plain payload
- `Precedence: bulk` header
- https://support.google.com/mail/answer/81126

##### Elements

- From: "Firstname from Company"
- From address SPF: `include:servers.mcsv.net`
- Subject: ...)
- Short preview line on top of the message
- Main hader line
- Subheader line
- Section: image + title + description + call2action  https://litmus.com/subscribe

### White lists

- https://www.dnswl.org/?page_id=87
- .

### Kitchen sink

- `echo > /etc/courier/aliasdir/.courier-kitchensink`
- alias: `any.address@any-domain.net:  kitchensink@localhost`

### Scan Class C network

```bash
for I in $(seq 1 255); do host -t A 1.2.3.${I}; done
```

### Email tests

- http://www.mail-tester.com/ by Mailpoet
- mailtest@unlocktheinbox.com
- https://www.unlocktheinbox.com/bulkemailvalidator/

### Email templates

- https://litmus.com/blog/go-responsive-with-these-7-free-email-templates-from-stamplia
- https://www.klaviyo.com/
