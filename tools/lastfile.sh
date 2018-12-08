#!/bin/bash
#
# Lists files in all subdirectories in order of modification time.
#
# VERSION       :1.0.1
# DATE          :2016-05-21
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/lastfile.sh

find . -type f "$@" -printf '%TY%Tm%Td%TH%TM %P\n' | sort -n
