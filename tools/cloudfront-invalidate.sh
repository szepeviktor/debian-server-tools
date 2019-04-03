#!/bin/bash
#
# Create an invalidation (purge) request on Amazon Cloudfront.
#
# VERSION       :0.1.0
# DATE          :2019-03-31
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :https://docs.aws.amazon.com/cli/latest/reference/cloudfront/create-invalidation.html
# DEPENDS       :pip3 install awscli
# LOCATION      :/usr/local/bin/cloudfront-invalidate.sh
# CONFIG        :/root/.aws/credentials

# Usage
#     DISTRIBUTION_ID=XXXX cloudfront-invalidate.sh /path/to/file ...

test -n "$DISTRIBUTION_ID" || exit 100

aws --profile=cloudfront cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "$@"
