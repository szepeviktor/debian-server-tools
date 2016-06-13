#!/usr/bin/env perl
#
# Decode an IMAP UTF-7 string.
#
# VERSION       :0.1.0
# DATE          :2015-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# REFS          :http://search.cpan.org/~pmakholm/Encode-IMAPUTF7-1.05/
# DEPENDS       :apt-get install libencode-imaputf7-perl
# LOCATION      :/usr/local/bin/decode-imap-utf7.pl

use Encode::IMAPUTF7;
use Encode qw/encode decode/;

print decode( 'IMAP-UTF-7', $ARGV[0] );

# apt-get install php5-imap -> imap_utf7_decode()
