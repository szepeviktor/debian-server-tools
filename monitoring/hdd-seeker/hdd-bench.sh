#!/bin/bash
#
# Measure disk access time
#
# VERSION       :0.2
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/root/hdd-bench/hdd-bench.sh
# DEPENDS       :apt-get install build-essential

# fill the disk with random data
# usage: filld <dir> <4K-blocks>
filld() {
    local FILLDIR="$1"
    local MAXSIZE="$2"
    local DIR="$FILLDIR"
    local -i SIZE="0"

    mkdir -p "$FILLDIR" &> /dev/null

    while [ "$SIZE" -lt "$MAXSIZE" ]; do
        # dir
        if [ $((RANDOM % 100)) == 0 ]; then
            DIR="$(mktemp -d "${FILLDIR}/XXXXXXXX")"
        fi

        # file
        FILE="$(mktemp "${DIR}/XXXXXXXX")"
        BLOCK4K=$((RANDOM % 64))
        [ -f "$FILE" ] || exit 1
        dd if=/dev/urandom of="$FILE" bs=4k count="$BLOCK4K" 2> /dev/null

        SIZE+="$BLOCK4K"
    done
}

# 1 million 4K blocks = 4 GB
#filld /filldir 1048576

# we need a compiler
which gcc &> /dev/null || exit 1

# https://github.com/baryluk
gcc -pthread -o seeker seeker_baryluk.c
# https://github.com/mlsorensen/seekmark
gcc -pthread -o seekmark seekmark-0.9.1.c

# VMware
DEVICE="/dev/sda"
# XEN
[ -b "$DEVICE" ] || DEVICE="/dev/xvda"
# KVM
[ -b "$DEVICE" ] || DEVICE="/dev/vda"
# first block device
if ! [ -b "$DEVICE" ]; then
    DEVICE="/dev/$(tail -n +3 /proc/partitions 2>/dev/null | head -n 1 | tr ' ' $'\n' | tail -n 1)"
    read -e -i "$DEVICE" -p "Disk to test? " DEVICE
fi
[ -r "$DEVICE" ] || exit 2

# SeekMark ~ 30 sec
ONESEC=$(./seekmark -f "$DEVICE" -t 2 -s 1000 \
    | grep -o ", [0-9.]* READ seeks per sec per thread$" | grep -o "[0-9]*" | head -n 1)

echo;echo "DIRECT benchmark (new)"
./seekmark -f "$DEVICE" -t 2 -s $((ONESEC * 30))
echo ------------------------------------

# seeker and hdparm reads only block devices
[ -b "$DEVICE" ] || exit 0

echo;echo "DIRECT benchmark"
./seeker "$DEVICE" 2
echo ------------------------------------

# hdparm
if ! which hdparm &> /dev/null; then
    echo "to install hdparm on a Debian based system issue:"
    echo "apt-get install hdparm"
    exit
fi

echo;echo "BUFFERED benchmark"
hdparm -t "$DEVICE"
echo ------------------------------------

echo;echo "CACHED benchmark"
hdparm -T "$DEVICE"

