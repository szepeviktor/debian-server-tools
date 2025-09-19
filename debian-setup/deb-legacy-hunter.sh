#!/bin/bash

exit 0

#aptitude search --disable-columns --display-format "%p" <TERMS>

# 100% sure to remove
apt autoremove --purge

# Not from stable
aptitude search '?and(?installed, ?not(?archive(stable)))'

# Not native architecture
aptitude search '?and(?installed, ?not(?architecture(native)))'

# Packages on hold
aptitude search '?and(?installed, ?action(hold))'

# Only configuration files left
aptitude search '?config-files'

# Transitional packages
aptitude search '?and(?installed, ?description(transitional))'

# Various legacy
aptitude search '?and(?installed, ?or(?garbage, ?broken, ?obsolete))'

# /etc - Broken symlinks
find /etc -xtype l -print0 | xargs -0 -- ls -l
# /etc - Ignored by etckeeper
git -C /etc status --short --ignored
# /etc - Legacy
find /etc -path "*.ucf-dist" -o -path "*.dpkg-old" -o -path "*.dpkg-dist" -o -path "*~"
