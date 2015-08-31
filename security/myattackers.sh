#!/bin/bash
#
# Ban malicious hosts manually.
#
# VERSION       :0.3.0
# DATE          :2015-08-31
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/myattackers.sh
# SYMLINK       :/usr/local/sbin/deny-ip.sh
# SYMLINK       :/usr/local/sbin/deny-http.sh
# SYMLINK       :/usr/local/sbin/deny-smtp.sh
# SYMLINK       :/usr/local/sbin/deny-ssh.sh
# CRON-HOURLY   :/usr/local/sbin/myattackers.sh
# CRON-MONTHLY  :/usr/local/sbin/myattackers.sh -z

CHAIN="MYATTACKERS"
SSH_PORT="22"

# Help
Usage() {
    cat << EOF
Usage: myattackers.sh [OPTION]... <ADDRESS>
       myattackers.sh [OPTION]... -l <FILE>
Ban malicious hosts manually.

Without parameters runs cron job to unban expired addresses without traffic.
  -i                    set up iptables chain
  -p <PROTOCOL>         ban only ports associated with this protocol
                          (ALL, SMTP, HTTP, SSH), default: ALL
  -t <BANTIME>          ban time (1d, 1m, p[ermanent]),
                          default: 1d
  -l <FILE>             read addresses from a file (one per line)
  -u                    unban one or more hosts
  -z                    reset one month old rule counters
  -h                    this help

EOF
    exit 1
}

# Output an error message
Error_msg() {
    echo -e "$(tput setaf 7;tput bold)$*$(tput sgr0)" >&2
}

# Detect an IPv4 address
Is_IP() {
    local TOBEIP="$1"
    #             0-9, 10-99, 100-199,  200-249,    250-255
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIP" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}$ ]]
}

# Detect an IPv4 address range
Is_IP_range() {
    local TOBEIPRANGE="$1"
    local MASKBITS="${TOBEIPRANGE##*/}"
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIPRANGE" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}/[0-9]{1,2}$ ]] \
        && [ "$MASKBITS" -gt 0 ] && [ "$MASKBITS" -le 30 ]
}

Check_chain() {
    iptables -n -L "$CHAIN" &> /dev/null
}

# Validate IP address or range
Check_address() {
    local ADDRESS="$1"

    Is_IP "$ADDRESS" || Is_IP_range "$ADDRESS"
}

Init() {
    if ! Check_chain; then
        iptables -N "$CHAIN" || return 1
        # Zero out counters
        iptables -Z "$CHAIN"
    fi

    # Final return rule
    if ! iptables -C "$CHAIN" -j RETURN &> /dev/null; then
        iptables -A "$CHAIN" -j RETURN || return 2
    fi

    # Enable our chain at the top of INPUT
    if ! iptables -C INPUT -j "$CHAIN" &> /dev/null; then
        iptables -I INPUT -j "$CHAIN" || return 3
    fi

    # All OK
    return 0
}

Bantime_translate() {
    local BANTIME="$1"
    local -i NOW="$(date "+%s")"

    case "$BANTIME" in
        1d|"")
            # 1 day
            echo "-m comment --comment @$((NOW + 86400))"
            ;;
        1m)
            # 30 days
            echo "-m comment --comment @$((NOW + 2592000))"
            ;;
        p|permanent)
            echo ""
            ;;
        *)
            Error_msg "Invalid period of time (${BANTIME})"
            exit 3
            ;;
    esac
}

Ban() {
    local ADDRESS="$1"

    # Don't populate duplicates
    if ! iptables -C "$CHAIN" -s "$ADDRESS" ${PROTOCOL_OPTION} -j DROP &> /dev/null; then
        # Insert at the top
        iptables -I "$CHAIN" -s "$ADDRESS" ${PROTOCOL_OPTION} ${BANTIME_OPTION} -j DROP
    fi
}

Unban() {
    local ADDRESS="$1"

    # Delete rule by searching for source address
    iptables --line-numbers -n -v -L "$CHAIN" \
        | sed -n "s;^\([0-9]\+\)\s\+[0-9]\+\s\+[0-9]\+\s\+DROP\s.*\s${ADDRESS//./\\.}\s\+0\.0\.0\.0/0\b.*$;\1;p" \
        | sort -r -n \
        | xargs -r -L 1 iptables -D "$CHAIN"
}

Get_rule_data() {
    # Format: LINE-NUMBER|PACKETS|EXPIRATION-DATE
    iptables --line-numbers -n -v -L "$CHAIN" \
        | sed -n "s;^\([0-9]\+\)\s\+\([0-9]\+\)\s\+[0-9]\+\s\+DROP\s\+\S\+\s\+--\s\+\*\s\+\*\s\+[0-9./]\+\s\+0\.0\.0\.0/0\b.*/\* @\([0-9]\+\) \*/.*$;\1|\2|\3;p" \
        | sort -r -n
}

# Unban expired addresses with zero traffic (hourly cron job)
Unban_expired() {
    local -i NOW="$(date "+%s")"

    Get_rule_data \
        | while read RULEDATA; do
            NUMBER="${RULEDATA%%|*}"
            PACKETS="${RULEDATA/*|0|*/Z}"
            declare -i EXPIRATION="${RULEDATA##*|}"

            # Zero traffic and expired
            if [ "$PACKETS" == "Z" ] && [ "$EXPIRATION" -le "$NOW" ]; then
                iptables -D "$CHAIN" "$NUMBER"
            fi
        done

    exit 0
}

# Zero out counters on rules expired at least one month ago (monthly cron job)
Reset_old_rule_counters() {
    local -i MONTH_AGO="$(date --date="1 month ago" "+%s")"

    Get_rule_data \
        | while read RULEDATA; do
            NUMBER="${RULEDATA%%|*}"
            declare -i EXPIRATION="${RULEDATA##*|}"

            # Expired one month ago
            if [ "$EXPIRATION" -le "$MONTH_AGO" ]; then
                # Zero the packet and byte counters
                iptables -Z "$CHAIN" "$NUMBER"
            fi
        done

    exit 0
}

# Script name specifies protocol
PROTOCOL="ALL"
case "$(basename $0)" in
    myattackers.sh)
        # Cron
        [ $# == 0 ] && Unban_expired
        ;;
    deny-http.sh)
        PROTOCOL="HTTP"
        ;;
    deny-smtp.sh)
        PROTOCOL="SMTP"
        ;;
    deny-ssh.sh)
        PROTOCOL="SSH"
        ;;
    deny-ip.sh)
        PROTOCOL="ALL"
        ;;
esac

# Get options
MODE="ban"
# Default ban time
BANTIME_OPTION="$(Bantime_translate "$OPTARG")"
LIST_FILE=""
while getopts ":ip:t:l:uzh" OPT; do
    case "$OPT" in
        i) # Protocol
            MODE="setup"
            ;;
        p) # Protocol
            PROTOCOL="$OPTARG"
            ;;
        t) # Ban time
            BANTIME_OPTION="$(Bantime_translate "$OPTARG")"
            ;;
        l) # List file
            LIST_FILE="$OPTARG"
            if ! [ -r "$LIST_FILE" ]; then
                echo "Read failure (${LIST_FILE})";
                exit 4
            fi
            ;;
        u) # Unban
            MODE="unban"
            ;;
        z) # Zero out counters on expired rules
            MODE="reset"
            ;;
        h)
            Usage
            ;;
        \?)
            Error_msg "Invalid option: -$OPTARG"
            Usage
            ;;
        :)
            Error_msg "Option -$OPTARG requires an argument."
            Usage
            ;;
    esac
done
shift $((OPTIND - 1))

case "$PROTOCOL" in
    http|HTTP)
        PROTOCOL_OPTION="-p tcp -m multiport --dports http,https"
        ;;
    smtp|SMTP)
        PROTOCOL_OPTION="-p tcp -m multiport --dports smtp,submission,smtps"
        ;;
    ssh|SSH)
        PROTOCOL_OPTION="-p tcp --dport ${SSH_PORT}"
        ;;
    all|ALL)
        # By default ban all traffic
        PROTOCOL_OPTION=""
        ;;
    *)
        Error_msg "Invalid protocol: ($PROTOCOL)"
        Usage
        ;;
esac

case "$MODE" in
    setup)
        if Init; then
            echo "iptables chain OK."
            exit 0
        else
            Error_msg "iptables chain setup error."
            exit 11
        fi
        ;;
esac

if ! Check_chain; then
    Error_msg "Please set up ${CHAIN} chain.\nmyattackers.sh -i"
    exit 10
fi

ADDRESS="$1"
if [ -z "$LIST_FILE" ] && ! Check_address "$ADDRESS"; then
    Error_msg "This is not a valid IPv4 address or range: (${ADDRESS})"
    Usage
fi

case "$MODE" in
    ban)
        if [ -z "$LIST_FILE" ]; then
            Ban "$ADDRESS"
        else
            # Skip empty and comment lines
            grep -Ev "^\s*#|^\s*$" "$LIST_FILE" \
                | while read ADDRESS; do
                    Check_address "$ADDRESS" && Ban "$ADDRESS"
                done
        fi
        ;;
    unban)
        if [ -z "$LIST_FILE" ]; then
            Unban "$ADDRESS"
        else
            grep -Ev "^\s*#|^\s*$" "$LIST_FILE" \
                | while read ADDRESS; do
                    Check_address "$ADDRESS" && Unban "$ADDRESS"
                done < "$LIST_FILE"
        fi
        ;;
    reset)
        Reset_old_rule_counters
        ;;
esac
