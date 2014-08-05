#!/bin/bash

# we need a compiler
which gcc &> /dev/null || exit 1

# https://github.com/baryluk
gcc -pthread -o seeker seeker_baryluk.c
# https://github.com/mlsorensen/seekmark
gcc -pthread -o seekmark seekmark-0.9.c

DEVICE="/dev/sda"
[ -b "$DEVICE" ] || DEVICE="/dev/xvda"
[ -b "$DEVICE" ] || read -p "Disk to test? " DEVICE
[ -b "$DEVICE" ] || exit 2


echo;echo DIRECT benchmark
./seeker $DEVICE 2

echo;echo DIRECT benchmark
./seeker $DEVICE 2

which hdparm &> /dev/null || exit 0

echo;echo BUFFERED benchmark
hdparm -t $DEVICE

echo;echo CACHED benchmark
hdparm -T $DEVICE

