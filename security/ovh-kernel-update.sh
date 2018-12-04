#!/bin/bash
#
# Automatic update for made-in-ovh OVH kernels.
#
# VERSION       :0.1.1
# DATE          :2014-12-03
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :http://help.ovh.co.uk/KernelInstall
# FEED          :http://www.ftp2rss.com/rss?v=1&ftp=ftp%3A%2F%2Fftp.ovh.net%2Fmade-in-ovh%2FbzImage&port=21&files=20
# DEPENDS       :apt-get install lftp s-nail
# LOCATION      :/usr/local/sbin/ovh-kernel-update.sh
# CRON-DAILY    :/usr/local/sbin/ovh-kernel-update.sh

OVH_KERNELS="ftp://ftp.ovh.net/made-in-ovh/bzImage/latest-production/"

CURRENT="$(ls /boot/*-xxxx-grs-ipv6-64-vps)"

# grsecurity + IPv6 + amd64 VPS
lftp -e "lcd /boot/; mirror -i '.*-xxxx-grs-ipv6-64-vps$'; bye" "$OVH_KERNELS"

NEW="$(ls /boot/*-xxxx-grs-ipv6-64-vps)"

if [ "$CURRENT" != "$NEW" ]; then
    # shellcheck disable=SC2012
    printf 'Run update-grub\nNewest kernels: %s' "$(ls -1 -t -r /boot/bzImage-* | tail -n 2)" \
        | s-nail -s "New kernel from OVH on $(hostname --fqdn)" root
fi

exit 0
