#!/usr/bin/perl
#
# A very simple RFC 2047 Unicode e-mail header field converter.
#
# VERSION       :0.2
# DATE          :2014-12-16
# AUTHOR        :Stanislaw Findeisen <stf at eisenbits.com>
# URL           :https://github.com/szepeviktor/debian-server-tools
# UPSTREAM      :https://github.com/sfindeisen/conv2047
# LOCATION      :/usr/local/bin/conv2047.pl
#
# Copyright (C) 2010,2014 Stanislaw Findeisen <stf at eisenbits.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Changes history:
#
# 2010-10-28 (STF) Initial version.
# 2014-12-16 (STF) Support for raw e-mails (fix from David Gauchard)

use warnings;
use strict;
use utf8;
use integer;

use POSIX qw(strftime locale_h);
use Encode qw/encode decode/;

use constant {
    VERSION      => '0.2',
    VERSION_DATE => '2014-12-16'
};

use Getopt::Long;

####################################
# Common stuff
####################################

sub trim {
    my $s = shift;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}

sub timeStampToStr {
    my $ts = shift;
    return strftime("%a, %d %b %Y %H:%M:%S %z %Z", gmtime($ts));
}

sub printPrefix {
    my $timeStr = timeStampToStr(time());
    my $prefix  = shift;
    unshift(@_, ($timeStr . ' '));
    unshift(@_, $prefix);

    my $msg = join('', @_);
    chomp($msg);
    $msg = encode('UTF-8', $msg);
    local $| = 1;
    print(STDERR "$msg\n");
}

sub debug {
    printPrefix('[debug] ', @_);
}

# level 2 debug
sub debug2 {
    printPrefix('[debug] ', @_);
}

sub debugTimes {
    my $msg = shift;
    my ($user, $system, $cuser, $csystem) = times();
    $msg = (defined($msg) ? ("($msg)") : '');
    debug("times $msg: $user/$system/$cuser/$csystem");
}

sub warning {
    printPrefix('[warn]  ', @_);
}

sub error {
    printPrefix('[error] ', @_);
}

sub info {
    printPrefix('[info]  ', @_);
}

sub fatal {
    error(@_);
    die(@_);
}

sub printHelp {
    my $ver           = VERSION();
    my $verdate       = VERSION_DATE();
    print <<"ENDHELP";
conv2047.pl $ver ($verdate)

Copyright (C) 2010 Stanislaw Findeisen <stf at eisenbits.com>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/>
This is free software: you are free to change and redistribute it.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A very simple RFC 2047 Unicode e-mail header field converter.

Usage:
  $0 [-c] -d
  $0 -e

The program reads header lines from standard input and tries
to decode or encode them.

Operation modes:
  -d decode (MIME-Header --> UTF-8)
  -e encode (UTF-8 --> MIME-Header)

Options:
  -c concatenate multiple output lines into 1

Example:
  echo "=?UTF-8?B?emHFvMOzxYLEhyBnxJnFm2zEhSBqYcW6xYQ=?=" | perl conv2047.pl -d
ENDHELP
}

####################################
# The program - main
####################################

my $help        = 0;
my $wantDecode  = 0;
my $wantEncode  = 0;
my $wantConcat  = 0;
my $clres = GetOptions('c' => \$wantConcat, 'd' => \$wantDecode, 'e' => \$wantEncode, 'help'  => \$help);

if (($help) or not ($wantDecode xor $wantEncode)) {
    printHelp();
    exit 0;
}

my $k = 0;

while (my $line = <>) {
    chomp($line);
    $line = decode('UTF-8', $line);
    # debug("[$k] got line [1]: $line");

    $line = ($wantDecode ? (decode('MIME-Header', $line)) : (encode('MIME-Header', $line)));
    # debug("[$k] got line [2]: $line");

    my $output = ($wantConcat ? $line : "$line\n");
       $output = encode('UTF-8', $output);
    print(STDOUT $output);

    $k++;
}

print(STDOUT "\n") if ($wantConcat and $k);
