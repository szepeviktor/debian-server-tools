# Can-send-email

Check email delivery.

It is possible to send the trigger message in three ways.

### PHP script

See: cse-add-client.sh

### Bounce message of a non-existent address

`can-send-email.sh --add BOUNCE-HOSTNAME mailto:DOESNT-EXIST@DOMAIN`

### Forwarded email address

`can-send-email.sh --add FORWARDED@ADDRESS mailto:FORWARDED@ADDRESS`
