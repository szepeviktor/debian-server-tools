#!/bin/bash

cd /root/dist-mod/
# CVE-2017-18925
wget "http://ftp.de.debian.org/debian/pool/main/o/opentmpfiles/opentmpfiles_0.3.1-1_all.deb"
dpkg -i opentmpfiles_*_all.deb
apt-get install systemd-tmpfiles
