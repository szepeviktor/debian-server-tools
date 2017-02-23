#!/bin/bash
#
# Display the total size of files in a list.
#
# VERSION       :0.1.0
# DATE          :2015-08-06
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install bc
# LOCATION      :/usr/local/bin/total.sh

# Usage
#
#     find -type f | total.sh
#     find /var/mail/domain.com/ -type f -mtime -60 | total.sh

xargs -I "%" stat -c %s "%" | paste -s -d "+" | bc
