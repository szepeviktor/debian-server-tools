#!/usr/bin/env python
# encoding: utf-8

# forked from: https://gist.github.com/cyberdelia/353112

from boto.s3.connection import S3Connection

AWS_ACCESS_KEY = '<aws access key>'
AWS_SECRET_KEY = '<aws secret key>'
AWS_BUCKET_NAME = '<aws bucket name>'
AWS_HEADERS = {
    'Cache-Control':'max-age=31536000, public'
}
AWS_ACL = 'public-read'

conn = S3Connection(AWS_ACCESS_KEY, AWS_SECRET_KEY)
bucket = conn.get_bucket(AWS_BUCKET_NAME)
bucket.make_public()

for key in bucket.list():
    print key.name
    key.set_contents_from_string(None, headers=AWS_HEADERS, replace=False, policy=AWS_ACL)
