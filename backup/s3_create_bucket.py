#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Create a new bucket on an S3 compatible host"""

from boto.s3.connection import S3Connection

S3_HOST = ''
S3_ACCESS_KEY = ''
S3_SECRET_KEY = ''
S3_NEW_BUCKET = ''

def main():
    """Entry point"""

    # Connect to host
    connection = S3Connection(S3_ACCESS_KEY, S3_SECRET_KEY, host=S3_HOST)

    # Create the new bucket
    connection.create_bucket(S3_NEW_BUCKET)

    # Test existence
    all_buckets = connection.get_all_buckets()
    for bucket in all_buckets:
        print('%s\n' % bucket)

if __name__ == '__main__':
    main()
