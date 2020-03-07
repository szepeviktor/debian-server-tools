#!/bin/bash

cd /root/dist-mod/
wget "http://ftp.de.debian.org/debian/pool/main/o/opentmpfiles/opentmpfiles_0.2+2019.05.21.git.44a55796ba-2_all.deb"
dpkg -i opentmpfiles_*_all.deb
apt-get install systemd-tmpfiles
