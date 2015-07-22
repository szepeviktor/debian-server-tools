#!/bin/bash
#
# Check your VPS' resources daily.
#
# VERSION       :0.4
# DATE          :2015-06-28
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install iproute heirloom-mailx
# LOCATION      :/usr/local/sbin/vpscheck.sh
# CONFIG        :~/.config/vpscheck/configuration
# CRON-DAILY    :/usr/local/sbin/vpscheck.sh

# Checks
# - CPU
# - memory
# - disks
# - swap
# - clock source
# - console
# - nameserver
# - IP address
# - gateway
# - nearest hop
# - MX
#
# Generate config
#     vpscheck.sh -gen
#
# PROC=1
# MEM=1048576
# PART="/dev/xvda,/dev/xvda1"
# SWAP=2097144
# CLOCK=xen
# CONSOLE=/dev/hvc0
# DNS1=8.8.8.8
# IP=95.140.33.67
# GW=95.140.33.1
# HOP=95.140.33.252
# # k.root-servers.net.
# HOP_TO=193.0.14.129
# MX=mail.szepe.net
#
# Examine the checks below: the `Add_check()` calls.
# Write your own checks!
# Report issues
#     https://github.com/szepeviktor/debian-server-tools/issues/new

Needs_root_commands() {
    [ "$(id --user)" == 0 ] || exit 1

    which ifconfig ip traceroute mailx &> /dev/null || exit 2
}

# http://www.root-servers.org/
Nearest_rootserver() {
    local NEAREST
    local MIN_HOPS="10"
    local HOPS

    for R in {a..z}; do
        # ICMP pings, maximun 10 hops, 2 seconds timeout
        HOPS="$(traceroute -4 -n -m 10 -w 2 "${R}.root-servers.net." 2>&1 \
            | tail -n +2 | wc -l; echo ${PIPESTATUS[0]})"

        # Traceroute is OK AND less hops than before
        if [ "${HOPS#*[^0-9]}" == 0 ] && [ "${HOPS%[^0-9]*}" -lt "$MIN_HOPS" ]; then
            NEAREST="${R}.root-servers.net."
            MIN_HOPS="${HOPS%[^0-9]*}"
        fi
    done

    echo "$NEAREST"
}

Add_check() {
    # FIXME keep original order
    CHECKS["$1"]="$2"
}

Translate() {
    local WORD="$1"
    local -A DICT=( [PROC]="CPU#irqbal" [MEM]="RAM" [PART]="DISK" [DNS1]="DNS" [GW]="GATEWAY" )

    if [ -z "${DICT[$WORD]}" ]; then
        echo "$WORD"
    else
        echo "${DICT[$WORD]}"
    fi
}

Check_vps() {
    local TR
    local CURRENT

    for C in ${!CHECKS[*]}; do
        # Variable name for this check
        CURRENT="CURRENT_${C}"
        # Assign value by running check
        eval "${CURRENT}=\"\$(${CHECKS[$C]})\""

        # User-friendly variable name in email
        if [ "$GENERATE_DEFAULTS" == 1 ]; then
            TR="$C"
        else
            TR="$(Translate "$C")"
        fi
        # Append to email contents
        eval "MAIL_CONTENT+=\"${TR}=${!CURRENT}\"\$'\n'"

        # Compare current value with config constant
        if [ "${!CURRENT}" != "${!C}" ]; then
            DIFF+="${TR} "
        fi
    done
}

# Add system tools' path
PATH+=":/sbin:/usr/sbin"

# Check current user and dependencies
Needs_root_commands

VPS_CONFIG="${HOME}/.config/vpscheck/configuration"

# Globals
declare -A CHECKS=( )
declare DIFF=""
declare MAIL_CONTENT=""
declare GENERATE_DEFAULTS=""

if [ "$1" == "-gen" ]; then
    GENERATE_DEFAULTS="1"
    HOP_TO="$(Nearest_rootserver)"
    echo "HOP_TO=${HOP_TO}"
else
    # Include config
    source "$VPS_CONFIG"
fi


# Number of CPU-s
Add_check PROC 'grep -c "^processor" /proc/cpuinfo'

# Total memory (kB)
Add_check MEM 'grep "^MemTotal:" /proc/meminfo | sed "s/\s\+/ /g" | cut -d" " -f 2'

# Disk partitions
# - VMware /dev/sd*
# - XEN /dev/xvd*
# - KVM dev/vd*
# - OpenVZ: no disk devices, comment out this check
Add_check PART 'ls -1 /dev/sd* | paste -s -d","'

# Swap sizes (kB)
Add_check SWAP 'tail -n +2 /proc/swaps | cut -f 2 | paste -s -d", "'

# Kernel clock source
Add_check CLOCK 'cat /sys/devices/system/clocksource/clocksource0/current_clocksource'

# Virtual console on Xen
#Add_check CONSOLE 'ls /dev/hvc0'

# First nameserver (IPv4 only)
Add_check DNS1 'grep -m 1 "^\s*[^#]*nameserver" /etc/resolv.conf | grep -o "[0-9.]*"'

# First IPv4 address
Add_check IP 'ip addr show|sed -n "s/^\s*inet \([0-9\.]\+\)\b.*$/\1/p"|grep -F -v -m 1 "127.0.0."'

# Default gateway (IPv4 only)
Add_check GW 'ip route | grep "^default via " | cut -d" " -f 3'
# FIXME "default dev venet0  scope link" if grep -w "default dev [[:alnum:]]\+ "; then grep \1

# First hop towards the nearest root server
Add_check HOP 'traceroute -n -m 1 ${HOP_TO} | tail -n 1 | cut -d" " -f 4'

# First mail exchanger
Add_check MX 'host -t MX $(hostname -f)|sed -n "0,/^.* mail is handled by [0-9]\+ \(\S\+\).*$/{s//\1/p}"'

Check_vps

if [ "$GENERATE_DEFAULTS" == 1 ]; then
    mkdir -p "$(dirname "$VPS_CONFIG")"
    echo "$MAIL_CONTENT"
    echo "Create config:  editor ${VPS_CONFIG}"
    exit
fi

[ -z "$DIFF" ] && exit 0

# Echo on terminal
if tty --quiet; then
    echo "DIFF=${DIFF}" >&2
else
    echo "$MAIL_CONTENT" | mailx -s "[vpscheck] WARNING - ${DIFF}changed" root
    exit 100
fi
