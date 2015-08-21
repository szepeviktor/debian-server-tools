#!/bin/bash
#
# Display bootlog with fixed escape sequences.
#
# VERSION       :1.0.0
# DATE          :2015-08-19
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# SOURCE        :http://stackoverflow.com/questions/10757823/display-file-with-escaped-color-codes-boot-messages-from-bootlog-daemon/10764254#10764254
# DEPENDS       :apt-get install bootlogd less
# LOCATION      :/usr/local/sbin/bootlog.sh

sed -e 's;\^\[;\o33;g' -e 's;\[1G\[;\[27G\[;' /var/log/boot | less -r
