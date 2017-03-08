#!/usr/bin/env python3
#
# Send SMS message through textlocal.com.
#
# VERSION        :1.0.1
# DATE           :2015-07-06
# AUTHOR         :Viktor Szépe <viktor@szepe.net>
# URL            :https://github.com/szepeviktor/debian-server-tools
# LICENSE        :The MIT License (MIT)
# PYTHON-VERSION :3.2+
# DOCS           :http://api.txtlocal.com/docs/
# LOCATION       :/usr/local/bin/txtlocal.py

# Fill in USERNAME and API_HASH
#
# Alternative Email to SMS method:
#     txtlocal@mydomain.net: |/usr/sbin/sendmail -f AUTHORIZED@ADDRESS PHONE-NUMBER@txtlocal.co.uk

USERNAME = ''
API_HASH = ''

import urllib.request
import urllib.parse
import json
import sys

def send_sms(uname, hash_code, numbers, message):
    txtlocal_api = 'https://api.txtlocal.com/send/?'
    parameters = {
        'username': uname,
        'hash': hash_code,
        'numbers': numbers,
        'message' : message,
        'sender': 'xreplyx',
        'format': 'json'
    }
    postdata = urllib.parse.urlencode(parameters)
    postdata = postdata.encode('utf-8')
    request = urllib.request.Request(txtlocal_api)
    with urllib.request.urlopen(request, postdata) as response:
        body = response.read()
    return body

def main(argv):
    resp = send_sms(USERNAME, API_HASH, argv[0], argv[1])
    # Debug: print(resp.decode('utf-8'))

    try:
        resp_array = json.loads(resp.decode('utf-8'))
    except:
        print('JSON error')
        return 10

    if 'status' in resp_array and resp_array['status'] == 'success':
        print('OK')
        return 0

    if ('errors' in resp_array
            and len(resp_array['errors'])
            and 'message' in resp_array['errors'][0]
            and 'code' in resp_array['errors'][0]):
        print(resp_array['errors'][0]['message'], file=sys.stderr)
        return resp_array['errors'][0]['code']
    else:
        print('Unknown response', file=sys.stderr)
        return 11

if __name__ == "__main__":
    exitcode = main(sys.argv[1:])
    sys.exit(exitcode)
