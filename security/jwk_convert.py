#!/usr/bin/python
"""Convert certbot private_key.json to manuale's account.json
Source: https://gist.github.com/JonLundy/f25c99ee0770e19dc595
``
./jwk_convert.py private_key.json > private-key.asn1
openssl asn1parse -genconf private-key.asn1 -noout -out private-key.der
openssl rsa -inform DER -in private-key.der -outform PEM -out private-key.key
echo -n '{"key": "' > account.json
paste -s -d '|' private-key.key | sed -e 's/|/\\n/g' | tr -d '\n' >> account.json
echo '", "uri": "https://acme-v01.api.letsencrypt.org/acme/reg/9999999"}' >> account.json # From regr.json
"""

from __future__ import print_function

import sys
import json
import base64
import binascii

with open(sys.argv[1]) as fp:
    PKEY = json.load(fp)


def enc(data):
    if isinstance(data, str):
        data = data.encode()
    missing_padding = 4 - len(data) % 4
    if missing_padding:
        data += b'=' * missing_padding
    return b'0x' + binascii.hexlify(base64.b64decode(data, b'-_')).upper()


if __name__ == '__main__':
    for k, v in PKEY.items():
        if k == 'kty':
            continue
        PKEY[k] = enc(v.encode())

    print("asn1=SEQUENCE:private_key\n[private_key]\nversion=INTEGER:0")
    print("n=INTEGER:{}".format(PKEY['n'].decode()))
    print("e=INTEGER:{}".format(PKEY['e'].decode()))
    print("d=INTEGER:{}".format(PKEY['d'].decode()))
    print("p=INTEGER:{}".format(PKEY['p'].decode()))
    print("q=INTEGER:{}".format(PKEY['q'].decode()))
    print("dp=INTEGER:{}".format(PKEY['dp'].decode()))
    print("dq=INTEGER:{}".format(PKEY['dq'].decode()))
    print("qi=INTEGER:{}".format(PKEY['qi'].decode()))
