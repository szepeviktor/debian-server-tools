#!/bin/bash
#
# Automatic update for made-in-ovh OVH kernels.
#
# VERSION       :0.1.0
# DATE          :2014-12-03
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :http://help.ovh.co.uk/KernelInstall
# FEED          :http://www.ftp2rss.com/rss?v=1&ftp=ftp%3A%2F%2Fftp.ovh.net%2Fmade-in-ovh%2FbzImage&port=21&files=20
# DEPENDS       :apt-get install lftp
# LOCATION      :/usr/local/sbin/ovh-kernel-update.sh
# CRON-DAILY    :/usr/local/sbin/ovh-kernel-update.sh


# grsecurity + IPv6 + amd64 VPS
OVH_KERNELS="ftp://ftp.ovh.net/made-in-ovh/bzImage/latest-production/"

CURRENT="$(ls /boot/*-xxxx-grs-ipv6-64-vps)"

cd /boot/
lftp -e "mirror -i '.*-xxxx-grs-ipv6-64-vps$'; bye" "$OVH_KERNELS"

NEW="$(ls /boot/*-xxxx-grs-ipv6-64-vps)"

if ! [ "$CURRENT" == "$NEW" ]; then
    echo -e "Reboot neccessary.\nnewest two kernels: $(ls -1tr /boot/bzImage-* | tail -n 2)" \
        | mailx -s "new kernel from OVH for $(hostname -s)" root
fi
