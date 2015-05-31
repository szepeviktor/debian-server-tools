#!/bin/bash
#
# Install all tools from debian-server-tools.
#

echo "Debian-server-tools installer"

# Directories
./install.sh ./backup
./install.sh ./image
./install.sh ./mail
./install.sh ./monitoring
./install.sh ./mysql
./install.sh ./package
./install.sh ./security
./install.sh ./tools
./install.sh ./webserver
./install.sh ./webserver/nginx-incron

# Single files
./install.sh "/root/hdd-bench" root:root 700 \
    ./monitoring/hdd-seeker/hdd-bench.sh
./install.sh "/root/hdd-bench" root:root 644 \
    ./monitoring/hdd-seeker/seeker_baryluk.c \
    ./monitoring/hdd-seeker/seekmark-0.9.1.c
