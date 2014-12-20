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
