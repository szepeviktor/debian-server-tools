#!/bin/bash

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
which hdparm &> /dev/null || exit 0

echo;echo "BUFFERED benchmark"
hdparm -t "$DEVICE"
echo ------------------------------------

echo;echo "CACHED benchmark"
hdparm -T "$DEVICE"

