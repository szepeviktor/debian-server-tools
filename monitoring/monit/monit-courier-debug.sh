#!/bin/bash
#
# Debug Courier outages.
#
# tcpdump -i any -n -v "port 53 or port 25"

LOG="/tmp/courier_$(date "+%H_%M_%S")"

Courier_dbg() {
    date --rfc-3339=seconds
    whoami
    echo -------------------------

    date --rfc-3339=seconds
    netstat -antup
    echo -------------------------

    date --rfc-3339=seconds
    RESOLVERS="$(sed -n -e 's/^nameserver\s\+\(\S\+\)\s*$/\1/p' /etc/resolv.conf)"
    while read -r RESOLVER; do
        if ! host -W 3 -t PTR 8.8.8.8 "$RESOLVER" &>/dev/null; then
            echo -n "Resolver failed: ${RESOLVER} "
        fi
    done <<<"$RESOLVERS"
    echo -------------------------

    date --rfc-3339=seconds
    #ps auxwww|grep courier|grep -v grep
    ps aufxwww
    echo -------------------------

    date --rfc-3339=seconds
    (sleep 1; echo -e 'QUIT\r') | nc localhost 25
    echo -------------------------

    date --rfc-3339=seconds
    (sleep 1; echo -e 'QUIT\r') | nc ::1 25
    echo -------------------------

    date --rfc-3339=seconds
    # EDIT
    (sleep 1; echo -e 'QUIT\r') | nc "$IPV6" 25
    echo -------------------------

    date --rfc-3339=seconds
    # EDIT
    (sleep 1; echo -e 'QUIT\r') | nc "$IP" 25 \
        || /etc/init.d/courier-mta restart
    echo -------------------------

    date --rfc-3339=seconds
    tail -n 20 /var/log/monit.log
    echo -------------------------

    date --rfc-3339=seconds
    tail -n 20 /var/log/syslog
    echo -------------------------
}

Courier_dbg >>"$LOG" 2>&1

mail -s "[$(hostname -f)] courier debug (see /tmp/)" admin@szepe.net <"$LOG"

# echo "12h" >respawnlo
