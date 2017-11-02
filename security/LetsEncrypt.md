# Let's Encrypt

SSL certificate for web, mail etc. See [/security/cert-update-manuale-CN.sh](/security/cert-update-manuale-CN.sh)

Test TLS connections, see [/security/README.md](/security/README.md)

[ManuaLE](https://github.com/veeti/manuale)

A fully manual Let's Encrypt/ACME client with DNS-based and HTTP challenge.

```bash
apt-get install -q -y ca-certificates \
    gcc python3-dev libssl-dev libffi-dev
cd /home/prg[0-9]*/
# With --ignore-installed cryptography may conflict with global package
u nice pip3 install --upgrade --user manuale
u mkdir --parents --mode=700 ssl/lets-encrypt
cd ssl/lets-encrypt/
read -r EMAIL
u ../../.local/bin/manuale register "$EMAIL"
u ../../.local/bin/manuale info; echo

# Issue or Renew
cd /home/prg[0-9]*/ssl/lets-encrypt/
read -r -e -i $(hostname -f) DOMAIN
#read -r DOMAIN2
u ../../.local/bin/manuale authorize $DOMAIN $DOMAIN2
# EC key: u ../../.local/bin/manuale issue --key-file param-${DOMAIN}-private.key $DOMAIN $DOMAIN2
u ../../.local/bin/manuale issue $DOMAIN $DOMAIN2
```

Add TXT record by AWS CLI

See [/monitoring/aws-route53-rrs.sh](/monitoring/aws-route53-rrs.sh)

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

[Certbot](https://github.com/certbot/certbot) *not recommended

```bash
# https://github.com/certbot/certbot/blob/master/certbot-auto#L246
apt-get install -y dialog ca-certificates python-dev gcc libssl-dev libffi-dev
apt-get install -t jessie-backports -y python-six
pip2 install --upgrade certbot

read -r EMAIL
read -r DOMAIN
#read -r DOMAIN2
# -d $DOMAIN2

# Manual for webservers
certbot certonly --verbose --text --manual --agree-tos --manual-public-ip-logging-ok --email $EMAIL -d $DOMAIN

# Webroot for webservers with port 80 open
#certbot certonly --verbose --text --webroot --agree-tos --email $EMAIL -d $DOMAIN --webroot-path=$DOC_ROOT

# Standalone for non-webservers
#certbot certonly --verbose --text --standalone --agree-tos --email $EMAIL -d $DOMAIN

( cd /etc/letsencrypt/live/$DOMAIN
  cat privkey.pem fullchain.pem > priv-pub-int.pem )
```

Renew

```bash
pip2 install --upgrade certbot
# https://certbot.eff.org/docs/using.html
certbot renew --verbose --manual --manual-public-ip-logging-ok
#certbot renew --verbose --standalone
#certbot renew --verbose --webroot --webroot-path=$DOCUMENT_ROOT

# Courier MTA
read -r CN
( cd /etc/letsencrypt/live/$DOMAIN
  cat privkey.pem cert.pem chain.pem > /etc/courier/esmtpd.pem )
rm -f /etc/courier/dhparams.pem
DH_BITS=2048 nice /usr/sbin/mkdhparams
courier-restart.sh
# Verify
openssl s_client -connect $(hostname -f):587 -starttls smtp < /dev/null
```

### Alternatives

- https://github.com/diafygi/acme-tiny
- https://github.com/lukas2511/letsencrypt.sh
- https://github.com/certbot/certbot/wiki/Links
