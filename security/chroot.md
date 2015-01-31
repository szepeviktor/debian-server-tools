CHROOT="/opt/www3debchroot"

debootstrap --arch amd64 --variant=minbase \
    --exclude cpio,cron,dmidecode,e2fslibs,e2fsprogs,gcc-4.8-base,ifupdown,hostname,init,init-system-helpers,initscripts,iproute2,iptables,isc-dhcp-client,isc-dhcp-common,kmod,logrotate,lsb-base,man-db,manpages,mount,net-tools,netcat-traditional,nfacct,passwd,rsyslog,sysv-rc,sysvinit-utils,tasksel,tasksel-data,vim-common,vim-tiny \
    jessie "$CHROOT" http://http.debian.net/debian

chroot $CHROOT

apt-get purge acl adduser dmsetup init initscripts insserv login mount systemd systemd-sysv
apt-get clean && rm -rf /var/lib/apt/lists/http* /usr/share/man /usr/share/doc /usr/share/locale
echo 'deb http://http.debian.net/debian jessie main contrib non-free
#deb http://security.debian.org/ jessie/updates main contrib non-free
' > /etc/apt/sources.list
du -sh /
