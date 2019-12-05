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
u pip3 install --no-warn-script-location --upgrade --user manuale
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
    "ResourceRecords": [ { "Value": "\"BBBBBBBBBBBBBBBB\"" } ],
    "TTL": 86400
  }
} ] }
```

### Alternatives

- https://github.com/diafygi/acme-tiny
- https://github.com/lukas2511/letsencrypt.sh
- https://github.com/certbot/certbot/wiki/Links
