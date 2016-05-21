#!/bin/bash
#
# Lists files in all subdirectories in modified time order.
#
# VERSION       :1.0.0
# DATE          :2016-05-20
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/lastfile.sh

find -type f "$@" -printf '%CY%Cm%Cd%CH%CM %P\n' | sort -n
