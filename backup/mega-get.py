#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Download a public file (or a file with known key) without logging in.
#
# VERSION       :1.0
# DATE          :2014-08-20
# URL           :https://github.com/szepeviktor/debian-server-tools
# LOCATION      :/usr/local/bin/mega-get.py
# DEPENDS       :pip install pycrypto
# ORIGIN        :http://julien-marchand.fr/blog/using-mega-api-with-python-examples/
# ORIGIN        :http://julien-marchand.fr/blog/using-the-mega-api-how-to-download-a-public-file-or-a-file-you-know-the-key-without-logging-in/
# USAGE         :mega.py '<PUBLIC-URL>'


from Crypto.Cipher import AES
from Crypto.PublicKey import RSA
from Crypto.Util import Counter

import base64
import binascii
import json
import os
import random
import struct
import sys
import urllib

sid = ''
seqno = random.randint(0, 0xFFFFFFFF)

master_key = ''
rsa_priv_key = ''

def base64urldecode(data):
    data += '=='[(2 - len(data) * 3) % 4:]
    for search, replace in (('-', '+'), ('_', '/'), (',', '')):
        data = data.replace(search, replace)
    return base64.b64decode(data)

def base64urlencode(data):
    data = base64.b64encode(data)
    for search, replace in (('+', '-'), ('/', '_'), ('=', '')):
        data = data.replace(search, replace)
    return data

def a32_to_str(a):
    return struct.pack('>%dI' % len(a), *a)

def a32_to_base64(a):
    return base64urlencode(a32_to_str(a))

def str_to_a32(b):
    if len(b) % 4: # Add padding, we need a string with a length multiple of 4
        b += '\0' * (4 - len(b) % 4)
    return struct.unpack('>%dI' % (len(b) / 4), b)

def base64_to_a32(s):
    return str_to_a32(base64urldecode(s))

def aes_cbc_encrypt(data, key):
    encryptor = AES.new(key, AES.MODE_CBC, '\0' * 16)
    return encryptor.encrypt(data)

def aes_cbc_decrypt(data, key):
    decryptor = AES.new(key, AES.MODE_CBC, '\0' * 16)
    return decryptor.decrypt(data)

def aes_cbc_encrypt_a32(data, key):
    return str_to_a32(aes_cbc_encrypt(a32_to_str(data), a32_to_str(key)))

def aes_cbc_decrypt_a32(data, key):
    return str_to_a32(aes_cbc_decrypt(a32_to_str(data), a32_to_str(key)))

def stringhash(s, aeskey):
    s32 = str_to_a32(s)
    h32 = [0, 0, 0, 0]
    for i in xrange(len(s32)):
        h32[i % 4] ^= s32[i]
    for _ in xrange(0x4000):
        h32 = aes_cbc_encrypt_a32(h32, aeskey)
    return a32_to_base64((h32[0], h32[2]))

def prepare_key(a):
    pkey = [0x93C467E3, 0x7DB0C7A4, 0xD1BE3F81, 0x0152CB56]
    for _ in xrange(0x10000):
        for j in xrange(0, len(a), 4):
            key = [0, 0, 0, 0]
            for i in xrange(4):
                if i + j < len(a):
                    key[i] = a[i + j]
            pkey = aes_cbc_encrypt_a32(pkey, key)
    return pkey

def encrypt_key(a, key):
    return sum((aes_cbc_encrypt_a32(a[i:i+4], key) for i in xrange(0, len(a), 4)), ())

def decrypt_key(a, key):
    return sum((aes_cbc_decrypt_a32(a[i:i+4], key) for i in xrange(0, len(a), 4)), ())

def mpi2int(s):
    return int(binascii.hexlify(s[2:]), 16)

def api_req(req):
    global seqno
    url = 'https://g.api.mega.co.nz/cs?id=%d%s' % (seqno, '&sid=%s' % sid if sid else '')
    seqno += 1
    return json.loads(post(url, json.dumps([req])))[0]

def post(url, data):
    return urllib.urlopen(url, data).read()

def enc_attr(attr, key):
    attr = 'MEGA' + json.dumps(attr)
    if len(attr) % 16:
        attr += '\0' * (16 - len(attr) % 16)
    return aes_cbc_encrypt(attr, a32_to_str(key))

def dec_attr(attr, key):
    attr = aes_cbc_decrypt(attr, a32_to_str(key)).rstrip('\0')
    return json.loads(attr[4:]) if attr[:6] == 'MEGA{"' else False

def get_chunks(size):
    chunks = {}
    p = pp = 0
    i = 1

    while i <= 8 and p < size - i * 0x20000:
        chunks[p] = i * 0x20000
        pp = p
        p += chunks[p]
        i += 1

    while p < size:
        chunks[p] = 0x100000
        pp = p
        p += chunks[p]

    chunks[pp] = size - pp
    if not chunks[pp]:
        del chunks[pp]

    return chunks

def getfile(file_id, file_key):
    key = base64_to_a32(file_key)
    k = (key[0] ^ key[4], key[1] ^ key[5], key[2] ^ key[6], key[3] ^ key[7])
    iv = key[4:6] + (0, 0)
    meta_mac = key[6:8]

    file = api_req({'a': 'g', 'g': 1, 'p': file_id})
    dl_url = file['g']
    size = file['s']
    attributes = base64urldecode(file['at'])
    attributes = dec_attr(attributes, k)

    print "Downloading %s (size: %d), url = %s" % (attributes['n'], size, dl_url)

    infile = urllib.urlopen(dl_url)
    outfile = open(attributes['n'], 'wb')
    decryptor = AES.new(a32_to_str(k), AES.MODE_CTR, counter=Counter.new(128, initial_value=((iv[0] << 32) + iv[1]) << 64))

    file_mac = [0, 0, 0, 0]
    for chunk_start, chunk_size in sorted(get_chunks(file['s']).items()):
        chunk = infile.read(chunk_size)
        chunk = decryptor.decrypt(chunk)
        outfile.write(chunk)

        chunk_mac = [iv[0], iv[1], iv[0], iv[1]]
        for i in xrange(0, len(chunk), 16):
            block = chunk[i:i+16]
            if len(block) % 16:
                block += '\0' * (16 - (len(block) % 16))
            block = str_to_a32(block)
            chunk_mac = [chunk_mac[0] ^ block[0], chunk_mac[1] ^ block[1], chunk_mac[2] ^ block[2], chunk_mac[3] ^ block[3]]
            chunk_mac = aes_cbc_encrypt_a32(chunk_mac, k)

        file_mac = [file_mac[0] ^ chunk_mac[0], file_mac[1] ^ chunk_mac[1], file_mac[2] ^ chunk_mac[2], file_mac[3] ^ chunk_mac[3]]
        file_mac = aes_cbc_encrypt_a32(file_mac, k)

    outfile.close()
    infile.close()

    if (file_mac[0] ^ file_mac[1], file_mac[2] ^ file_mac[3]) != meta_mac:
        print "MAC mismatch"
    else:
        print "MAC OK"


if __name__ == '__main__':
    if len(sys.argv) == 2:
        # https://mega.co.nz/#!aaaaaaaa!bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
        url = sys.argv[1]
        url_parts = url.split('!')
        if len(url_parts) != 3:
            print "Invalid mega URL"
            sys.exit(1)

        getfile(url_parts[1], url_parts[2])
    else:
        print "Usage: mega.py <public-url>"
