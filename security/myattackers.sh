#!/bin/bash
#
# Ban malicious hosts manually.
#
# VERSION       :0.7.1
# DATE          :2018-02-15
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install iptables-persistent
# LOCATION      :/usr/local/sbin/myattackers.sh
# SYMLINK       :/usr/local/sbin/deny-ip.sh
# SYMLINK       :/usr/local/sbin/deny-http.sh
# SYMLINK       :/usr/local/sbin/deny-smtp.sh
# SYMLINK       :/usr/local/sbin/deny-ssh.sh
# CRON-HOURLY   :/usr/local/sbin/myattackers.sh
# CRON-MONTHLY  :/usr/local/sbin/myattackers.sh -z

# Default /etc/iptables/rules.v4 content
#
#     :myattackers - [0:0]
#     -A INPUT -j myattackers
#     -A myattackers -j RETURN

CHAIN="myattackers"

# Help
Usage() {
    cat <<EOF
Usage: myattackers.sh [OPTION]... <ADDRESS>
       myattackers.sh [OPTION]... -l <FILE>
Ban malicious hosts manually.

Without parameters runs cron job to unban expired addresses without traffic.
  -i                    set up iptables chain
  -d                    show iptables chain removal commands
  -s                    show active rules
  -p <PROTOCOL>         ban only ports associated with this protocol
                          (ALL, SMTP, IMAP, HTTP, SSH), default: ALL
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
Error_msg()
{
    if [ -t 0 ]; then
        echo -e "$(tput setaf 7;tput bold)${*}$(tput sgr0)" 1>&2
    else
        echo -e "${*}" 1>&2
    fi
}

# Detect an IPv4 address
Is_IP()
{
    local TOBEIP="$1"
    #             0-9, 10-99, 100-199,  200-249,    250-255
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIP" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}$ ]]
}

# Detect an IPv4 address range
Is_IP_range()
{
    local TOBEIPRANGE="$1"
    local MASKBITS="${TOBEIPRANGE##*/}"
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIPRANGE" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}/[0-9]{1,2}$ ]] \
        && [ "$MASKBITS" -gt 0 ] && [ "$MASKBITS" -le 30 ]
}

Check_chain()
{
    /sbin/iptables -n -w -L "$CHAIN" 2>/dev/null | grep -q ' (1 references)$'
}

# Validate IP address or range
Check_address()
{
    local ADDRESS="$1"

    Is_IP "$ADDRESS" || Is_IP_range "$ADDRESS"
}

Get_ssh_port()
{
    /usr/sbin/sshd -T -C user=root -C host=localhost -C addr=localhost | sed -n -e 's#^port \([0-9]\+\)$#\1#p'
}

Init()
{
    if ! Check_chain; then
        /sbin/iptables -w -N "$CHAIN" || return 1
        # Zero out counters
        /sbin/iptables -w -Z "$CHAIN"
    fi

    # Final return rule
    if ! /sbin/iptables -w -C "$CHAIN" -j RETURN &>/dev/null; then
        /sbin/iptables -w -A "$CHAIN" -j RETURN || return 2
    fi

    # Enable our chain at the top of INPUT
    if ! /sbin/iptables -w -C INPUT -j "$CHAIN" &>/dev/null; then
        /sbin/iptables -w -A INPUT -j "$CHAIN" || return 3
    fi

    # All OK
    return 0
}

Remove_chain()
{
    echo "iptables -w -D INPUT -j ${CHAIN}"
    echo "iptables -w -F ${CHAIN}"
    echo "iptables -w -X ${CHAIN}"
}

Show()
{
    # Show only rules sorted by source IP
    /sbin/iptables -v -n -w -L ${CHAIN} \
        | grep -F -w "REJECT" | sort -t "." -k 1.48,1n -k 2,2n -k 3,3n -k 4,4n
}

Bantime_translate()
{
    local BANTIME="$1"
    local -i NOW

    NOW="$(date "+%s")"

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

Ban()
{
    local ADDRESS="$1"

    # Don't populate duplicates
    # shellcheck disable=SC2086
    if ! /sbin/iptables -w -C "$CHAIN" -s "$ADDRESS" ${PROTOCOL_OPTION} -j REJECT &>/dev/null; then
        # Insert at the top
        # shellcheck disable=SC2086
        /sbin/iptables -w -I "$CHAIN" -s "$ADDRESS" ${PROTOCOL_OPTION} ${BANTIME_OPTION} -j REJECT
        logger -t "myattackers" "Ban ${ADDRESS} PROTO=${PROTOCOL}"
    fi
}

Unban()
{
    local ADDRESS="$1"

    # Delete rule by searching for source address
    /sbin/iptables -n -v -w --line-numbers -L "$CHAIN" \
        | sed -n -e "s#^\\([0-9]\\+\\)\\s\\+[0-9]\\+\\s\\+[0-9]\\+[KMG]\\?\\s\\+REJECT\\s.*\\s${ADDRESS//./\\.}\\s\\+0\\.0\\.0\\.0/0\\b.*\$#\\1#p" \
        | sort -r -n \
        | xargs -r -L 1 /sbin/iptables -w -D "$CHAIN"
    logger -t "myattackers" "Unban ${ADDRESS}"
}

Get_rule_data()
{
    # Output format: LINE-NUMBER <TAB> PACKETS <TAB> IP-ADDRESS <TAB> EXPIRATION-DATE
    /sbin/iptables -n -v -w --line-numbers -L "$CHAIN" \
        | sed -n -e 's#^\([0-9]\+\)\s\+\([0-9]\+\)\s\+[0-9]\+[KMG]\?\s\+REJECT\s\+\S\+\s\+--\s\+\*\s\+\*\s\+\([0-9./]\+\)\s\+0\.0\.0\.0/0\b.*/\* @\([0-9]\+\) \*/.*$#\1\t\2\t\3\t\4#p' \
        | sort -r -n
}

# Unban expired addresses with zero traffic (hourly cron job)
Unban_expired()
{
    local -i NOW
    local -i MONTH_AGO
    local NUMBER
    local -i PACKETS
    local SOURCE
    local -i EXPIRATION

    NOW="$(date "+%s")"
    MONTH_AGO="$(date --date="1 month ago" "+%s")"

    Get_rule_data \
        | while IFS=$'\t' read -r -a RULEDATA; do
            NUMBER="${RULEDATA[0]}"
            PACKETS="${RULEDATA[1]}"
            SOURCE="${RULEDATA[2]}"
            EXPIRATION="${RULEDATA[3]}"

            # Had zero traffic and expired in the last 1 month period
            if [ "$PACKETS" -eq 0 ] \
                && [ "$EXPIRATION" -le "$NOW" ] \
                && [ "$EXPIRATION" -gt "$MONTH_AGO" ]; then
                /sbin/iptables -w -D "$CHAIN" "$NUMBER"
                logger -t "myattackers" "Unban expired ${SOURCE}"
            fi
        done
}

# Zero out counters on rules expired at least one month ago (monthly cron job)
Reset_old_rule_counters()
{
    local -i MONTH_AGO
    local NUMBER
    local -i PACKETS
    local SOURCE
    local -i EXPIRATION

    MONTH_AGO="$(date --date="1 month ago" "+%s")"

    Get_rule_data \
        | while IFS=$'\t' read -r -a RULEDATA; do
            NUMBER="${RULEDATA[0]}"
            PACKETS="${RULEDATA[1]}"
            SOURCE="${RULEDATA[2]}"
            EXPIRATION="${RULEDATA[3]}"

            # Expired at least one month ago
            # These survived the hourly deletion
            if [ "$EXPIRATION" -le "$MONTH_AGO" ]; then
                if [ "$PACKETS" -eq 0 ]; then
                    # Remove rules with zero traffic
                    # These must be at least 2 months old
                    /sbin/iptables -w -D "$CHAIN" "$NUMBER"
                    logger -t "myattackers" "Unban expired 1+ months ${SOURCE}"
                else
                    # Reset the packet and byte counters
                    /sbin/iptables -w -Z "$CHAIN" "$NUMBER"
                fi
            fi
        done
}

# Script name specifies protocol
PROTOCOL="ALL"
MODE="ban"
case "$(basename "$0")" in
    myattackers.sh)
        # Cron hourly (when called without parameters)
        test "$#" == 0 && MODE="cron"
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

# Default ban time
BANTIME_OPTION="$(Bantime_translate "")"
LIST_FILE=""
while getopts ":idsp:t:l:uzh" OPT; do
    case "$OPT" in
        i) # Initialize
            MODE="setup"
            ;;
        d) # Remove chain
            MODE="remove"
            ;;
        s) # Show rules
            MODE="show"
            ;;
        p) # Protocol
            PROTOCOL="$OPTARG"
            ;;
        t) # Ban time
            BANTIME_OPTION="$(Bantime_translate "$OPTARG")"
            ;;
        l) # List file
            LIST_FILE="$OPTARG"
            if [ ! -r "$LIST_FILE" ]; then
                echo "List file read failure (${LIST_FILE})";
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
            Error_msg "Invalid option: -${OPTARG}"
            Usage
            ;;
        :)
            Error_msg "Option -${OPTARG} requires an argument."
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
    imap|IMAP)
        PROTOCOL_OPTION="-p tcp -m multiport --dports imap2,imaps"
        ;;
    ssh|SSH)
        PROTOCOL_OPTION="-p tcp --dport $(Get_ssh_port)"
        ;;
    all|ALL)
        # By default ban all traffic
        PROTOCOL_OPTION=""
        ;;
    *)
        Error_msg "Invalid protocol: (${PROTOCOL})"
        Usage
        ;;
esac

# Modes before chain check
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
    remove)
        Remove_chain
        exit 0
        ;;
esac

if ! Check_chain; then
    Error_msg "Please set up ${CHAIN} chain.\\nmyattackers.sh -i"
    exit 10
fi

# Modes without a specific host
case "$MODE" in
    cron)
        Unban_expired
        exit 0
        ;;
    show)
        Show
        exit 0
        ;;
    reset)
        Reset_old_rule_counters
        exit 0
        ;;
esac

ADDRESS="$1"
if [ -z "$LIST_FILE" ] && ! Check_address "$ADDRESS"; then
    Error_msg "This is not a valid IPv4 address or range: (${ADDRESS})"
    Usage
fi

# Modes with a specific host
case "$MODE" in
    ban)
        if [ -z "$LIST_FILE" ]; then
            Ban "$ADDRESS"
        else
            # Skip empty and comment lines
            grep -E -v '^\s*#|^\s*$' "$LIST_FILE" \
                | while read -r LADDRESS; do
                    Check_address "$LADDRESS" && Ban "$LADDRESS"
                done
        fi
        ;;
    unban)
        if [ -z "$LIST_FILE" ]; then
            Unban "$ADDRESS"
        else
            grep -E -v '^\s*#|^\s*$' "$LIST_FILE" \
                | while read -r LADDRESS; do
                    Check_address "$LADDRESS" && Unban "$LADDRESS"
                done
        fi
        ;;
esac
