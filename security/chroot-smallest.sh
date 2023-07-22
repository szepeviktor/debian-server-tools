#!/bin/bash
#
# Smallest chroot environment.
#

exit 0

CHROOT="/opt/www3debchroot"
TARGET="jessie"

debootstrap --arch=amd64 --variant=minbase \
    --exclude=cpio,cron,dmidecode,ifupdown,init-system-helpers,iproute2,iptables,\
isc-dhcp-client,isc-dhcp-common,kmod,logrotate,man-db,manpages,net-tools,\
netcat-traditional,nfacct,rsyslog,tasksel,tasksel-data,vim-common,vim-tiny \
    ${TARGET} ${CHROOT} http://http.debian.net/debian

cp -v /etc/hosts ${CHROOT}/etc/hosts

cat > ${CHROOT}/etc/apt/sources.list <<EOF
deb http://http.debian.net/debian ${TARGET} main contrib non-free

deb http://security.debian.org/ ${TARGET}/updates main contrib non-free
EOF

echo "alias aptclean='apt-get clean && rm -rf \
/var/lib/apt/lists/http* /usr/share/man/* /usr/share/doc/* /usr/share/locale/*'" \
    >> ${CHROOT}/root/.bashrc

mount --bind /proc ${CHROOT}/proc \
    && mount --bind /sys ${CHROOT}/sys \
    && TERM=xterm chroot "$CHROOT"

#     apt-get purge --force-yes \
#       acl adduser cpio cron dmidecode dmsetup e2fslibs e2fsprogs \
#       ifupdown hostname init initscripts init-system-helpers insserv iproute2 iptables \
#       isc-dhcp-client isc-dhcp-common kmod login logrotate man-db manpages mount \
#       net-tools netcat-traditional nfacct passwd rsyslog \
#       sysv-rc systemd systemd-sysv sysvinit-utils tasksel tasksel-data vim-common vim-tiny
#
#     aptclean
#     du -sh /
#     exit

umount ${CHROOT}/proc ${CHROOT}/sys
