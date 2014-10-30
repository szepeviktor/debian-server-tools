#!/bin/bash
#
# Debian setup (wheezy amd64).
# Not really a sctipr but a manual.
#

# identify
lsb_release -a

# packages sources
nano /etc/apt/sources.list
# OVH's local mirror: http://debian.mirrors.ovh.net/debian
# server4you: http://debian.intergenia.de/debian
# closest mirror http://http.debian.net/debian
# national mirror: http://ftp.<COUNTRY-CODE>.debian.org/debian
deb <MIRROR> wheezy  main contrib non-free
# security
deb http://security.debian.org/ wheezy/updates  main contrib non-free
# updates (previously known as 'volatile')
deb <MIRROR> wheezy-updates  main
# backports
# http://backports.debian.org/changes/wheezy-backports.html
deb <MIRROR> wheezy-backports  main

# after root login
apt-get clean
apt-get autoremove --purge
apt-get update
apt-get install -y ssh mc most lftp bash-completion sudo htop bind9-host ncurses-term
apt-get install -t wheezy-backports rsyslog whois

# input
export PS1="[\[$(tput setaf 3)\]\u\[\033[1;31m\]@\h\[$(tput sgr0)\]:\[$(tput setaf 8)\]\[$(tput setab 4)\]\w\[$(tput sgr0)\]:\t:\[$(tput setaf 0)\]\!\[$(tput sgr0)\]]\n"
ls -1 /usr/share/mc/skins/
export MC_SKIN='modarin256root-defbg'
echo "alias e='mcedit'" > /etc/profile.d/editor.sh || echo "ERROR: alias 'e'"
sed -i 's/^# \(".*: history-search-.*ward\)$/\1/' /etc/inputrc || echo "ERROR: history-search-backward"
sed -e 's/\(#.*enable bash completion\)/#\1/' -e '/#.*enable bash completion/,+8 { s/^#// }' -i /etc/bash.bashrc || echo "ERROR: bash completion"
update-alternatives --config editor

# user
adduser viktor
K="<PUBLIC-KEY>"
S=/home/viktor/.ssh; mkdir --mode 700 $S; echo $K >> authorized_keys2; chown viktor:viktor $S
adduser viktor sudo
# log in
sudo su - || exit

# remove root password
e /etc/shadow
# ssh on port 3022
sed 's/^Port 22$/#Port 22\nPort 3022/' -i /etc/ssh/sshd_config
service ssh restart

# IPv6 ???
e /etc/network/interfaces
e /etc/resolv.conf
#nameserver 8.8.8.8
#nameserver 8.8.4.4
#nameserver <LOCAL_NS>
#options timeout:2
wget -O /usr/local/sbin/vpscheck.sh https://github.com/szepeviktor/debian-server-tools/raw/master/monitoring/vpscheck.sh
chmod +x /usr/local/sbin/vpscheck.sh
vpscheck.sh -gen
# hostname
H="<HOST-NAME>"
hostname $H
echo $H > /etc/hostname
# locale
dpkg-reconfigure locales
# comment out getty[2-6]
e /etc/inittab

# sanitize users
e /etc/passwd
# sanitize packages (-hardware-related +monitoring -daemons)
dpkg -l|grep -v "^ii"
# apt-get purge
dpkg -l|most
# sanitize files
apt-get autoremove --purge
apt-get install -y debconf-utils unattended-upgrades apt-listchanges cruft debsums
echo "dash dash/sh boolean false"|debconf-set-selections -v
dpkg-reconfigure -f noninteractive dash
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true"|debconf-set-selections -v
dpkg-reconfigure -f noninteractive unattended-upgrades
cruft
debsums -c

# fail2ban new version: https://tracker.debian.org/pkg/fail2ban
apt-get install -y -t wheezy-backports init-system-helpers
apt-get install -y geoip-database-contrib geoip-bin recode python3-pyinotify
dget -ux <DSC-URL>
dpkg-checkbuilddeps
dpkg-buildpackage -b -us -uc
dpkg -i --dry-run <PACKAGE>
e /etc/fail2ban/jail.local

# suhosin: https://github.com/stefanesser/suhosin/releases


# colorized less
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
            man "$@"
}
