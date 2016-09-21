# Let's Encrypt

# SSL certificate for web, mail etc.
# See /security/new-ssl-cert.sh

# Test TLS connections
# See /security/README.md

[Certbot client](https://github.com/certbot/certbot)

```bash
apt-get install -y dialog ca-certificates python-dev gcc libssl-dev libffi-dev
apt-get install -t jessie-backports -y python-six
pip2 install --upgrade certbot

read -r DOMAIN
read -r EMAIL
# -d $DOMAIN2

# Manual for webservers
certbot certonly --verbose --text --manual --agree-tos --manual-public-ip-logging-ok --email $EMAIL -d $DOMAIN

# Webroot for webservers with port 80 open
#certbot certonly --verbose --text --webroot --agree-tos --email $EMAIL -d $DOMAIN --webroot-path=$DOC_ROOT

# Standalone for non-webservers
#certbot certonly --verbose --text --standalone --agree-tos --email $EMAIL -d $DOMAIN

cat /etc/letsencrypt/live/${DOMAIN}/privkey.pem /etc/letsencrypt/live/${DOMAIN}/fullchain.pem \
    > priv-pub-int.pem

# DNS-based challenge
#     https://github.com/veeti/manuale
apt-get install -y dialog ca-certificates \
    gcc python3-dev libssl-dev libffi-dev
pip3 install --upgrade manuale
manuale -h
```

Add TXT record by AWS CLI

`aws route53 change-resource-record-sets --hosted-zone-id "/hostedzone/AAAAAAAAA" --change-batch file://acme-challenge.json`

```json
{ "Changes": [ {
  "Action": "CREATE",
  "ResourceRecordSet": {
    "Name": "_acme-challenge.DOMAIN.TLD.",
    "Type": "TXT",
    "ResourceRecords": [ { "Value": "\"AAAAAAAAAAAAAAAA\"" } ],
    "TTL": 86400
  }
} ] }
```

### Renew

```bash
pip2 install --upgrade certbot
# https://certbot.eff.org/docs/using.html
certbot renew --verbose --manual --manual-public-ip-logging-ok
#certbot renew --verbose --standalone
#certbot renew --verbose --webroot --webroot-path=/path/to/doc-root

( cd /etc/letsencrypt/live/mail.radiomedinstruments.hu
cat privkey.pem cert.pem chain.pem > /etc/courier/esmtpd.pem )
rm -f /etc/courier/dhparams.pem
DH_BITS=2048 nice /usr/sbin/mkdhparams
courier-restart.sh
# Verify
openssl s_client -connect $(hostname -f):587 -starttls smtp < /dev/null
```

### Alternatives

- https://github.com/diafygi/acme-tiny
- https://github.com/veeti/manuale
- https://github.com/lukas2511/letsencrypt.sh
- https://github.com/certbot/certbot/wiki/Links
