### Outlook 2013

- Root: "Inbox"
- after account setup: [delete .pst/.ost file](http://answers.microsoft.com/en-us/office/forum/office_2013_release-outlook/outlook-2013-with-imap-deleted-items-and-trash-i/9ec6e501-8e1a-45cf-bb90-cb9e2205d025)

### Email sending and receiving

- SSL?
- headers: From, from name, To, Reply-to, Return-path, SMTP "MAIL FROM:"
- 

### Bulk email

https://support.google.com/mail/answer/81126?hl=en

#### SPF

- setup
- check
- monitor

#### DKIM

- setup
- check
- monitor

#### DMARC

Specs: https://datatracker.ietf.org/doc/draft-kucherawy-dmarc-base/?include_text=1

- setup https://unlocktheinbox.com/dmarcwizard/
- check mailto:mailtest@unlocktheinbox.com
- monitor `host -t TXT <domain>`

#### Headers

- List-Unsubscribe: <URL>
- Precedence: bulk
- Return-Path:, Reply-to:, From:, To:, Subject:
- SMTP "MAIL FORM: <from@addre.ss>"

#### Content

- online version
- who (email address) is subscribed
- contact
- unsubscribe link
- HTML and plain payload
