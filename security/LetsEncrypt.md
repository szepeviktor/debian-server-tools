# Let's Encrypt

[Certbot client](https://github.com/certbot/certbot)

```bash
apt-get install -y python python-dev gcc dialog libssl-dev libffi-dev ca-certificates
pip2 install certbot
# -d DOMAIN2 -d DOMAIN3 --agree-tos --email EMAIL
certbot certonly --no-self-upgrade --standalone -d $DOMAIN
cat /etc/letsencrypt/live/${DOMAIN}/privkey.pem /etc/letsencrypt/live/${DOMAIN}/fullchain.pem \
    > priv-pub-int.pem
```

### Alternatives

- https://github.com/diafygi/acme-tiny
- https://github.com/veeti/manuale
- https://github.com/lukas2511/letsencrypt.sh
- https://github.com/certbot/certbot/wiki/Links
