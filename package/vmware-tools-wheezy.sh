#!/bin/sh
#
# Install VMware tools Tools for virtual machines hosted on VMware (CLI)
# This is NOT a shell script but you can figure out what to do.
#
# VERSION       :0.2
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+

exit 0

# Debian has a package
# https://packages.debian.org/wheezy-backports/open-vm-tools
# from upstream http://sourceforge.net/projects/open-vm-tools/files/open-vm-tools/

# Add VMware tools Debian repository - http://packages.vmware.com/tools/versions
echo "deb http://packages.vmware.com/tools/esx/latest/ubuntu precise main" > /etc/apt/sources.list.d/vmware-tools.list

# fake upstart
dpkg-divert --local --rename --add /sbin/initctl
ln -vfs /bin/true /sbin/initctl

apt-get install vmware-tools-services vmware-tools-user

# start on boot
ln -sv /etc/vmware-tools/init/vmware-tools-services /etc/init.d/vmware-tools-services

# prepend this to /etc/vmware-tools/init/vmware-tools-services
# and on every update


### BEGIN INIT INFO
# Provides:          vmware-tools-services
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# X-Start-Before:
# X-Stop-After:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description: The VMware Tools Daemon service enables fundamental host/guest functionality between a VM and its host.
# Short-Description: Enables VMware host/guest functionality.
### END INIT INFO

insserv -vf vmware-tools-services

# on update
# update-rc.d vmware-tools-services start 20 2 3 4 5 . stop 20 0 1 6 .
