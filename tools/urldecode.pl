#!/usr/bin/perl -p
#
# Decode piped URL-s.
#
# VERSION       :0.1.0
# LOCATION      :/usr/local/bin/urldecode.pl

# Usage
#
#     echo "URL%40encoded" | urldecode.pl

s/\%([A-Fa-f0-9]{2})/pack("C", hex($1))/seg;
