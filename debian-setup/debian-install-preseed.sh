#!/bin/bash

exit 0

# Automated Debian install with preseed file
#
# - two instances on the same private network with DHCP
# - One is a webserver with the preseed file
# - Two is autmatically installed: auto url=http://192.168.1.2/path/to/preseed.file
# - see https://www.debian.org/releases/stable/amd64/apb.html


# Debian Installer steps (Expert Install)
#
#  1. Default language and location = English/United States
#  2. Locale = en_US.UTF-8
#  3. Keyboard = American English
#  4. Network = DHCP or static IP, DNS resolver, host name
#  5. Users = no root login, "debian" user, standard password
#  6. Timezone = use NTP, UTC
#  7. Disks = 300MB boot part, use LVM: 2GB swap, min. 3GB root
#  8. Base system = linux-image-amd64
#  9. APT sources = per country mirror, non-free and backports, no popcon
# 10. Tasksel = SSH + standard
# 11. Boot loader = GRUB, no EFI
