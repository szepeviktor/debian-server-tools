#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Measures HTTP response time and show it on stderr
# Use -S option to show HTTP response on stdout
#
# VERSION       :1.0
# DATE          :2014-08-01
# URL           :https://github.com/szepeviktor/debian-server-tools
# LOCATION      :/usr/local/bin/wetransfer.py
# DEPENDS       :pip install requests
# SOURCE        :https://github.com/superalex/py-wetransfer


from urlparse import urlparse, parse_qs
import requests, sys, json, re, getopt, sys

__version__ = '1.0'

DOWNLOAD_URL_PARAMS_PREFIX = 'downloads/'
CHUNK_SIZE = 1024

def download(file_id, recipient_id, security_hash):
    url = 'https://www.wetransfer.com/api/v1/transfers/{0}/download?recipient_id={1}&security_hash={2}&password=&ie=false'.format(file_id, recipient_id, security_hash)
    r = requests.get(url)
    download_data = json.loads(r.content)

    print 'Downloading {0}...'.format(url)
    if download_data.has_key('direct_link'):
        content_info_string = parse_qs(urlparse(download_data['direct_link']).query)['response-content-disposition'][0]
        file_name = re.findall('filename="(.*?)"', content_info_string)[0].encode('ascii', 'ignore')
        r = requests.get(download_data['direct_link'], stream=True)
    else:
        file_name = download_data['fields']['filename']
        r = requests.post(download_data['formdata']['action'], data=download_data['fields'], stream=True)

    file_size = int(r.headers['Content-Length'])
    output_file = open(file_name, 'w')
    counter = 0
    for chunk in r.iter_content(chunk_size=CHUNK_SIZE):
        if chunk:
            output_file.write(chunk)
            output_file.flush()
            sys.stdout.write('\r{0}% {1}/{2}'.format((counter * CHUNK_SIZE) * 100 / file_size, counter * CHUNK_SIZE, file_size))
            counter += 1

    sys.stdout.write('\r100% {0}/{1}\n'.format(file_size, file_size))
    output_file.close()
    print 'Finished! {0}'.format(file_name)


def extract_params(url):
    """
        Extracts params from url
    """
    params = url.split(DOWNLOAD_URL_PARAMS_PREFIX)[1].split('/')
    [file_id, recipient_id, security_hash] = ['', '', '']
    if len(params) > 2:
        #The url is similar to https://www.wetransfer.com/downloads/XXXXXXXXXX/YYYYYYYYY/ZZZZZZZZ
        [file_id, recipient_id, security_hash] = params
    else:
        #The url is similar to https://www.wetransfer.com/downloads/XXXXXXXXXX/ZZZZZZZZ
        #In this case we have no recipient_id
        [file_id, security_hash] = params

    return [file_id, recipient_id, security_hash]


def extract_url_redirection(url):
    """
        Follow the url redirection if necesary
    """
    return requests.get(url).url

def usage():
    print """
You should have a we transfer address similar to https://www.wetransfer.com/downloads/XXXXXXXXXX/YYYYYYYYY/ZZZZZZZZ

So execute:
    python wetransfer.py -u https://www.wetransfer.com/downloads/XXXXXXXXXXXXXXXXXXXXXXXXX/YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY/ZZZZZ

And download it! :)
"""
    sys.exit()


def main(argv):
    try:
        opts, args = getopt.getopt(argv, 'u:h', ['url', 'help'])
        url = None
        for opt, arg in opts:
            if opt in ('-u', '--url'):
                url = arg
            if opt in ('-h', '--help'):
                usage()

        if argv[0].find('http') == 0:
            url = argv[0]

        if not url:
            usage()

        url = extract_url_redirection(url)
        [file_id, recipient_id, security_hash] = extract_params(url)
        download(file_id, recipient_id, security_hash)

    except getopt.GetoptError:
        usage()
        sys.exit(2)


if __name__ == '__main__':
    main(sys.argv[1:])
