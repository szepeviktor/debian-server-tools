#!/usr/bin/python
"""Convert certbot private_key.json to manuale's account.json
Source: https://gist.github.com/JonLundy/f25c99ee0770e19dc595

./jwk_convert.py private_key.json > private-key.asn1
openssl asn1parse -genconf private-key.asn1 -noout -out private-key.der
openssl rsa -inform DER -in private-key.der -outform PEM -out private-key.key
echo -n '{"key": "' > account.json
paste -s -d '|' private-key.key | sed -e 's/|/\\n/g' | tr -d '\n' >> account.json
echo '", "uri": "https://acme-v01.api.letsencrypt.org/acme/reg/9999999"}' >> account.json # From regr.json
"""

import sys
import json
import base64
import binascii
with open(sys.argv[1]) as fp:
    PKEY = json.load(fp)


def enc(data):
    missing_padding = 4 - len(data) % 4
    if missing_padding:
        data += b'=' * missing_padding

    return '0x'+binascii.hexlify(base64.b64decode(data, b'-_')).upper()

for k, v in PKEY.items():
    if k == 'kty':
        continue
    PKEY[k] = enc(v.encode())

print "asn1=SEQUENCE:private_key\n[private_key]\nversion=INTEGER:0"
print "n=INTEGER:{}".format(PKEY[u'n'])
print "e=INTEGER:{}".format(PKEY[u'e'])
print "d=INTEGER:{}".format(PKEY[u'd'])
print "p=INTEGER:{}".format(PKEY[u'p'])
print "q=INTEGER:{}".format(PKEY[u'q'])
print "dp=INTEGER:{}".format(PKEY[u'dp'])
print "dq=INTEGER:{}".format(PKEY[u'dq'])
print "qi=INTEGER:{}".format(PKEY[u'qi'])
