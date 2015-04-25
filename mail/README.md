### Outlook 2013

- Root: "Inbox"
- to recognize standard folder names [delete .pst/.ost file](http://answers.microsoft.com/en-us/office/forum/office_2013_release-outlook/outlook-2013-with-imap-deleted-items-and-trash-i/9ec6e501-8e1a-45cf-bb90-cb9e2205d025)
after account setup
- (Outlook 2007) empty folder subscription, see: mail/courier-outlook-subscribe-bug.sh

### Set up Google Apps mailing

https://toolbox.googleapps.com/apps/checkmx/

### Mail account migration

see: mail/imapsync

### Send messages in an mbox file to an email address

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

#### Sender ID

- http://en.wikipedia.org/wiki/Sender_ID
- http://tools.ietf.org/html/rfc4407#section-2
- PRA: Resent-Sender > Resent-From > Sender > From > ill-formed
- http://www.appmaildev.com/

#### SPF (MAIL FROM:)

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

#### Bulk mail musts

- link to online version
- who (email address) is subscribed
- sender's contact details
- unsubscribe link
- HTML and plain payload
- `Precedence: bulk` header
- https://support.google.com/mail/answer/81126

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