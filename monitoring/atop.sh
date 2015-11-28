#!/bin/bash
#
# Successful non-static HTTP requests
#
# LOCATION      :/usr/local/bin/atop.sh

tail -f /var/log/apache2/*access.log \
    | grep -v '\] "GET /.\+\.[a-z]\+ HTTP/1\.1" 200 '
