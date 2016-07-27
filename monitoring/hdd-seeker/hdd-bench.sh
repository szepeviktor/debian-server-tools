#!/bin/bash
#
# Measure disk access time
#
# VERSION       :0.6.0
# DATE          :2015-04-14
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/root/hdd-bench/hdd-bench.sh
# DEPENDS       :apt-get install build-essential hdparm ioping

# Fill the disk with random data
# usage: filld <dir> <4K-blocks>
Filld() {
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
#Filld /filldir 1048576

# We need a compiler
which gcc &> /dev/null || exit 1

# https://github.com/baryluk
gcc -pthread -o seeker seeker_baryluk.c
# https://github.com/mlsorensen/seekmark
gcc -pthread -o seekmark seekmark-0.9.1.c

# VMware/pysical
DEVICE="/dev/sda"
# XEN
[ -b "$DEVICE" ] || DEVICE="/dev/xvda"
# KVM
[ -b "$DEVICE" ] || DEVICE="/dev/vda"
# first block device
if ! [ -b "$DEVICE" ]; then
    DEVICE="/dev/$(tail -n +3 /proc/partitions 2> /dev/null | head -n 1 | tr ' ' $'\n' | tail -n 1)"
    read -r -e -i "$DEVICE" -p "Disk to test? " DEVICE
fi
[ -r "$DEVICE" ] || exit 2

# Standard dd with fdatasync
echo;echo "DD to filesystem"
time { dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync; sync; }
echo "------------------------------------"

# SeekMark ~ 30 sec
ONESEC=$(./seekmark -f "$DEVICE" -t 2 -s 1000 \
    | grep -o ", [0-9.]* READ seeks per sec per thread\$" | grep -o "[0-9]*" | head -n 1)

echo;echo "DIRECT benchmark (new)"
./seekmark -f "$DEVICE" -t 2 -s $((ONESEC * 30))
echo "------------------------------------"

# Seeker and hdparm reads only block devices
[ -b "$DEVICE" ] || exit 0

echo;echo "DIRECT benchmark";echo
./seeker "$DEVICE" 2
echo "------------------------------------"

rm seeker seekmark test

# Hdparm
if ! which hdparm &> /dev/null; then
    echo "to install hdparm on a Debian-based system:"
    echo "apt-get install -y hdparm"
    echo "hdparm -t ${DEVICE}"
    echo "hdparm -T ${DEVICE}"
    exit
fi

echo;echo "BUFFERED benchmark"
hdparm -t "$DEVICE"
echo "------------------------------------"

echo;echo "CACHED benchmark"
hdparm -T "$DEVICE"
echo "------------------------------------"

# Ioping
if ! which ioping &> /dev/null; then
    echo "to install ioping on a Debian-based system:"
    echo "apt-get install -y ioping"
    echo "ioping -q -i 0 -w 5 -S 64m ${DEVICE}"
    echo "ioping -q -i 0 -w 5 -S 64m -L ${DEVICE}"
    exit
fi

echo;echo "RANDOM ioping (64m working set)"
ioping -q -i 0 -w 5 -S 64m "$DEVICE"
echo "------------------------------------"

echo;echo "SEQUENTIAL ioping (64m working set)"
ioping -q -i 0 -w 5 -S 64m -L "$DEVICE"
echo "------------------------------------"
