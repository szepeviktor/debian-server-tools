#!/usr/bin/perl -p
#
# Encode piped URL-s.
#
# VERSION       :0.1.0
# LOCATION      :/usr/local/bin/urlencode.pl

# Usage
#
#     echo "URL decoded" | urlencode.pl

s/([^0-9A-Za-z_.!~*()'-])/sprintf("%%%02X", ord($1))/eg;
