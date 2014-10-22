#!/bin/bash
#
# Check your VPS' resources daily.
# CPU, memory, disks, swap, clock source, console, nameserver, IP address, gateway, nearest hop
#
# VERSION       :0.1
# DATE          :2014-10-22
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install iproute heirloom-mailx
# LOCATION      :/usr/local/sbin/vpscheck
# CRON-DAILY    :/usr/local/sbin/vpscheck

###################

# First generate your values:  vpscheck -gen
# E.g.

PROC=1
MEM=1048576
PART="/dev/xvda,/dev/xvda1"
SWAP=2097144
CLOCK=xen
CONSOLE=/dev/hvc0
DNS1=8.8.8.8
IP=95.140.33.67
GW=95.140.33.1
HOP=95.140.33.252
# k.root-servers.net.
HOP_TO=193.0.14.129

# Then examine the checks below (many Add_check calls)
# Write your own checks!
# Report issues: https://github.com/szepeviktor/debian-server-tools/issues/new

###################

Necessary() {
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
        HOPS="$(traceroute -n -m 10 -w 2 "${R}.root-servers.net." 2>&1 \
            | tail -n +2 | wc -l; echo ${PIPESTATUS[0]})"

        # traceroute is OK AND less hops than before
        if [ "${HOPS#*[^0-9]}" == 0 ] && [ "${HOPS%[^0-9]*}" -lt "$MIN_HOPS" ]; then
            NEAREST="${R}.root-servers.net."
            MIN_HOPS="${HOPS%[^0-9]*}"
        fi
    done

    echo "$NEAREST"
}

Add_check() {
    CHECKS["$1"]="$2"
}

Translate() {
    local WORD="$1"
    local -A DICT=( [PROC]="CPU#" [MEM]="RAM" [PART]="DISK" [DNS1]="DNS" [GW]="GATEWAY" )

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
        # set current variable name
        CURRENT="CURRENT_${C}"
        # give it a value, thus run check
        eval "${CURRENT}=\"\$(${CHECKS[$C]})\""

        # user-friendly variable name
        if [ "$GENERATE_DEFAULTS" == 1 ]; then
            TR="$C"
        else
            TR="$(Translate "$C")"
        fi
        # append email content
        eval "MAIL_CONTENT+=\"${TR}=${!CURRENT}\"\$'\n'"

        # if current value differs from given constant value
        if [ "${!CURRENT}" != "${!C}" ]; then
            DIFF+="${TR} "
        fi
    done
}


# check user and dependencies
Necessary

declare -A CHECKS=()
unset DIFF
unset MAIL_CONTENT

if [ "$1" == "-gen" ]; then
    GENERATE_DEFAULTS="1"
    HOP_TO="$(Nearest_rootserver)"
    echo "HOP_TO=${HOP_TO}"
fi


# number of CPU-s
Add_check PROC 'grep -c "^processor" /proc/cpuinfo'

# total memory (kB)
Add_check MEM 'grep "^MemTotal:" /proc/meminfo | sed "s/\s\+/ /g" | cut -d" " -f 2'

# available disk partitions
# - VMware /dev/sd*
# - XEN /dev/xvd*
# - KVM dev/vd*
Add_check PART 'ls -1 /dev/xvd* | paste -s -d","'

# swap sizes (kB)
Add_check SWAP 'tail -n +2 /proc/swaps | cut -f 2 | paste -s -d", "'

# kernel clock source
Add_check CLOCK 'cat /sys/devices/system/clocksource/clocksource0/current_clocksource'

# virtual console
Add_check CONSOLE 'ls /dev/hvc0'

# first nameserver (IPv4 only)
Add_check DNS1 'grep -m 1 "^\s*[^#]*nameserver" /etc/resolv.conf | grep -o "[0-9.]*"'

# first IPv4 address
Add_check IP 'ip addr show | grep -o "inet [0-9.]*" | grep -v -m 1 "127.0.0.1" | cut -d" " -f 2'

# default gateway (IPv4 only)
Add_check GW 'ip route | grep "^default via " | cut -d" " -f 3'

# first hop towards the nearest root server
Add_check HOP 'traceroute -n -m 1 ${HOP_TO} | tail -n 1 | cut -d" " -f 4'


Check_vps

if [ "$GENERATE_DEFAULTS" == 1 ]; then
    echo "$MAIL_CONTENT"
    exit
fi

[ -z "$DIFF" ] && exit 0

echo "$MAIL_CONTENT" | mailx -s "[vpscheck] WARNING!!! ${DIFF}changed" root
