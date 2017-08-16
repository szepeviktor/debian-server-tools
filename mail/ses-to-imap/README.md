# SES-to-IMAP

Receiving emails with Amazon SES, S3 and SNS to an IMAP mailbox.

Internet → Amazon SES → S3 storage → SNS notification → local web hook → incron job → s3cmd

### Setup

1. Local IMAP server and accounts
1. SES send - SMTP
1. SES receive / Email Receiving / Rule Sets: store to S3 bucket and notify SNS topic
1. `ses-sns-notifications` directory
1. Install PHP script: `https://example.com/ses-sns/endpoint.php` append to message list file: `user@domain.tld`
1. Add incron job: `/home/USER/website/ses-emails IN_CREATE,IN_MODIFY /usr/local/bin/ses-mail-download.sh $@ $#`
1. `ses-get-messages.sh` download messages to the specified inbox with s3cmd and clear the S3 bucket
1. SNS / Topics: Protocol HTTPS




- Log in https://console.aws.amazon.com/
- SES
    enabled region EU (Ireland) US East (N. Virginia) US West (Oregon)
    domain + dkim
    add dns: Verification, DKIM, MX
    wait for verification
- SES Receipt
    Rule
    info@
    S3 ses-wip/info
    SNS ses-wip-info
    Rule name info-wip

    a SES fogadja akárhonnan, szűr vírust, spam-et amennyire tud
    berakja egy S3 bucket-be mint egy sima .eml fájlt
    az SNS szól egy nálunk lévő PHP programocskának, hogy jött levél
    a PHP program hozzáadja a levél ID-ját egy szöveg fájlhoz
    ezt figyeli az incron job, ami elindít egy szkriptet
    az pedig letölti a levelet és berakja a levélfiókodba :)
- SES SMTP
    Sending Statistics - sandbox
    create cred.
- SNS
    Topics
    deploy PHP code, composer update
    `composer require aws/aws-php-sns-message-validator`
    Create subscr HTTPS https://lampa.wip.services/ses-sns/endpoint.php
    confirm URL
- Test
    Publish { "default": "{\"tag\": 11}" }
    From: szepeviktor@aruba.it (verified)
console window!
    See file in /home/USER/website/ses-sns-notifications
- Courier imap
    hosted domain
    auth userdb
    add user
- RainLoop
    imap+smtp
- incron
    apt install
    incron shell script
    allow USER
    incrontab -u USER incrontab
- Test email
    From: szepeviktor@aruba.it (verified)
- Courier SMTP settings
    esmtpd/2

TODO

Bounces SNS
Complaints SNS
