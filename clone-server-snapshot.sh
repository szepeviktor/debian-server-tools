#!/bin/bash
#
# Clone a Debian-based server by a snapshot.
#

exit 0

# On the "donor" before snapshoting

# Switch to DHCP
apt-get install -qq isc-dhcp-client
cp -a /etc/network/interfaces /etc/network/interfaces.clone
cp -a /etc/resolv.conf /etc/resolv.conf.clone
editor /etc/network/interfaces
#ifdown eth0; ifup eth0

### Do snapshot! ###

# Revert after snapshoting
mv -f /etc/network/interfaces.clone /etc/network/interfaces
mv -f /etc/resolv.conf.clone /etc/resolv.conf
#ifdown eth0; ifup eth0


# On the "clone"

# IP address
editor /etc/network/interfaces
rm -f /etc/network/interfaces.clone
ifdown eth0; ifup eth0
mv -f /etc/resolv.conf.clone /etc/resolv.conf

# Hostname
# See: /debian-setup.sh

# DNS A
host -t A "$H"

# DNS PTR
host -t PTR "$IP"

# DNS MX
host -t MX "$H"

# SSH host keys (needs new hostname)
rm -vf /etc/ssh/ssh_host_*
dpkg-reconfigure -f noninteractive openssh-server

# Server data
editor /root/server.yml

# Cron jobs
mc /etc/cron.d/ /var/spool/cron/crontabs/

# Courier MTA
editor /etc/courier/me
host -t MX "$(head -n 1 /etc/courier/me)"
editor /etc/courier/defaultdomain
editor /etc/courier/dsnfrom
editor /etc/courier/aliases/system
editor /etc/courier/aliases/system-user
courier-restart.sh

# Add clone on the smart host !!!
#     alias
#     smtpaccess

# Backups

# MySQL DB-s and users

# Apache "prg" site URL

# Reconfigure other services

# When finished
reboot
