#!/bin/bash
#
# Skype over RDP
#
# DEB           :https://www.skype.com/en/download-skype/skype-for-linux/downloading-web/?type=weblinux-deb
# REPO          :https://repo.skype.com/

USERNAME="user"

#apt-get install -y bash-completion && . /etc/bash_completion

# 32 bit dependencies
dpkg --add-architecture i386
apt-get update
apt-get install -y libc6:i386 libqt4-dbus:i386 libqt4-network:i386 libqt4-xml:i386 \
    libqtcore4:i386 libqtgui4:i386 libqtwebkit4:i386 libstdc++6:i386 libx11-6:i386 \
    libxext6:i386 libxss1:i386 libxv1:i386 libssl1.0.0:i386 libpulse0:i386 \
    libasound2-plugins:i386 pulseaudio xorg xrdp xfce4 xfce4-goodies \
    iceweasel

# Add a user
adduser ${USERNAME}
# @FIXME XRDP does not support RDP Audio
adduser ${USERNAME} audio

# Set language
dpkg-reconfigure locales # hu_HU.UTF-8

# Skype
wget -O skype-install.deb "http://www.skype.com/go/getskype-linux-deb"
dpkg -i skype-install.deb
# Hungarian language files
wget -O- "http://urbalazs.hu/blog/uploads/skype_hu_4.3.0.37.tar.gz" \
    | tar --directory /usr/share/skype/lang/ -xz
