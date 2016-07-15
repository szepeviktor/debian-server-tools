#!/bin/bash
#
# Install mc on cPanel as a normal user.
#

# CentOS 6 repo
MC_REPO="http://download.opensuse.org/repositories/home:/laurentwandrebeck:/mc/CentOS_6/x86_64"
# CentOS 7 repo
#MC_REPO="http://download.opensuse.org/repositories/home:/laurentwandrebeck:/mc/CentOS_7/x86_64/"
MC_RPM="mc-4.8.17-3.1.x86_64.rpm"
BINARIES="https://github.com/szepeviktor/debian-server-tools/raw/master/package/bin.el6"

set -e

Progressbar() {
    sed -e 's|^.*$|.|g' | tr -d '\n'
}

cat > ~/.bashrc <<EOF
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export MC_SKIN=dark
EOF

# Get utils
mkdir ~/bin || true
wget -nv -P ~/bin/ "${BINARIES}/rpm2cpio"
wget -nv -P ~/bin/ "${BINARIES}/cpio"
chmod +x ~/bin/*

# Download RPM
mkdir -p ~/rpm/mc
cd ~/rpm/mc/
wget -nv -nc "${MC_REPO}/${MC_RPM}"
# Unpack RPM to ~/rpm/mc/etc and ~/rpm/mc/usr
rpm2cpio mc-*x86_64.rpm | cpio -id

# Install mc
mkdir -vp ~/.config/mc/mcedit ~/.local/share/mc ~/.mc | Progressbar
# Syntax
cp -va usr/share/mc/syntax/* ~/.config/mc/mcedit/ | Progressbar
# Make includes use absolute path
sed -i -e "s|^include |include ${HOME}/.config/mc/mcedit/|" ~/.config/mc/mcedit/Syntax
# Skins
cp -va usr/share/mc/skins ~/.local/share/mc/ | Progressbar
# Don't use aspell, terminal is UTF-8 (missing /usr/share/mc/mc.charsets)
cat >> ~/.config/mc/ini <<EOF
[Misc]
#display_codepage=UTF-8
display_codepage=Other_8_bit
source_codepage=Other_8_bit
spell_language=NONE

EOF
# Append global config
cat usr/share/mc/mc.lib  >> ~/.config/mc/ini
# Configuration files
cp -va etc/mc ~/.config/ | Progressbar
# libexec
cp -va usr/libexec/mc/* ~/.mc/ | Progressbar
# Binaries
cp -va usr/bin/ ~/ | Progressbar
echo

mc --version
rm -rf etc usr
