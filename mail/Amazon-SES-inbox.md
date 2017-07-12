# Receiving emails with Amazon SES, S3 and SNS

Internet → Amazon SES → S3 storage → SNS notification → local web hook → incron job → s3cmd

- SES / Email Receiving / Rule Sets: store to S3 bucket and notify SNS topic
- SNS / Topics: Protocol HTTPS
- `https://example.com/ses-sns/endpoint.php` append to message list file: `user@domain.tld`
- incron: `/home/USER/website/ses-emails IN_CREATE,IN_MODIFY /usr/local/bin/ses-mail-download.sh $@ $#`
- `ses-mail-download.sh` download messages to the specified inbox with s3cmd and clear the S3 bucket

composer require aws/aws-php-sns-message-validator
