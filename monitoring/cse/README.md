# Can-send-email

Check email delivery.

It is possible to send the trigger message in three ways.

### PHP script

See: cse-add-client.sh

`can-send-email.sh --add HOSTNAME http://HOSTNAME/SECRET-DIR/cse.php`

### Bounce message of a non-existent address

`can-send-email.sh --add BOUNCE-HOSTNAME mailto:DOESNT-EXIST@DOMAIN`

### Forwarded email address

`can-send-email.sh --add FORWARDED@ADDRESS mailto:FORWARDED@ADDRESS`

## Whitelist sender IP-s

It is very important to whitelist all sender IP-s on CSE server.
