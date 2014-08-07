#!/usr/bin/env python
# -*- coding: utf-8 -*-

# forked from: https://gist.github.com/cyberdelia/353112

import s3_config
from boto.s3.connection import S3Connection

conn = S3Connection(s3_config.AWS_ACCESS_KEY, s3_config.AWS_SECRET_KEY)
bucket = conn.get_bucket(s3_config.AWS_BUCKET_NAME)
bucket.make_public()

for key in bucket.list():
    print key.name
    key.set_contents_from_string(None, headers=s3_config.AWS_HEADERS, replace=False, policy=s3_config.AWS_ACL)

