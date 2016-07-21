# Let's Encrypt

[Certbot client](https://github.com/certbot/certbot)

```bash
apt-get install -y python python-dev gcc dialog libssl-dev libffi-dev ca-certificates
apt-get install -t jessie-backports -y python-six
pip2 install --upgrade certbot

read -r DOMAIN
# -d DOMAIN2 -d DOMAIN3 --agree-tos --email EMAIL
certbot certonly -v --no-self-upgrade --standalone -d $DOMAIN
cat /etc/letsencrypt/live/${DOMAIN}/privkey.pem /etc/letsencrypt/live/${DOMAIN}/fullchain.pem \
    > priv-pub-int.pem
```

### Renew

```bash
# https://certbot.eff.org/docs/using.html
certbot renew -v --standalone
#certbot renew -v --webroot --webroot-path=/path/to/doc-root
```

### Alternatives

- https://github.com/diafygi/acme-tiny
- https://github.com/veeti/manuale
- https://github.com/lukas2511/letsencrypt.sh
- https://github.com/certbot/certbot/wiki/Links
