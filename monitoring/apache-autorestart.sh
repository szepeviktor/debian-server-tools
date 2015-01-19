#!/bin/bash
#
# Mini DoS mitigation for Apache webserver
# Restart Apache on high loads (HTTP floods)
#
# VERSION       :0.2
# DATE          :2014-08-11
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :/usr/local/bin/ncget-time.sh
# DEPENDS       :apt-get install procps netcat-traditional heirloom-mailx bc
# LOCATION      :/usr/local/sbin/apache-autorestart.sh
# CRON          :* *  * * *  root  /usr/local/sbin/apache-autorestart.sh
# EXCEL_FUNC    :=JOBB("0" & ÓRA(SOR(A2)/24/60); 2) & ":" & JOBB("0" & PERC(SOR(A2)/24/60);2)
# FIND-CAUSE    :grep "05/Jan/2014:13:0[0-6]:" /home/*/log/access*.log /var/log/apache2/access*.log | sort -k4 -t' ' | less


# notification email address
NOTIFY_EMAIL="sms@szepe.net"

# server's public IP
SERVER="95.140.33.67"

# static test file
URL="http://www.online1.hu/piwik.js"

# activity log path
LOG="/var/log/apache2/autorestart.log"

SERVICE="apache2"
SERVICE_PID="/var/run/apache2.pid"
ERROR="erR"
SCORE=0
REPEAT=0
PID=$$

# singleton
exec 200< "$0"
flock -n 200 || exit 0

# english only
export LC_ALL=C

round() {
    echo "$*/1" | bc -q 2> /dev/null
}

apache_count() {
    pgrep -c "$SERVICE" 2> /dev/null
}

debug() {
    echo -n "$(date "+%b %e %H:%M:%S") apache-autorestart[${PID}]: @${1}; apache#=$(apache_count)" >> "$LOG"
}

force_restart() {
    debug "restart() started: before stop"

    /usr/sbin/service "$SERVICE" stop > /dev/null 2>&1
    rm -f "$SERVICE_PID"

    debug "after stop"
    while [ "$(apache_count)" != 0 ]; do
        sleep 2
        debug "after 1st sleep"

        killall "$SERVICE"
        debug "after SIGTERM"

        sleep 3
        debug "after 2nd sleep"

        killall --signal SIGKILL "$SERVICE"
        debug "after SIGKILL"
    done

    # let MySQL finish
    sleep 10

    debug "before start"
    # send output to cron
    /usr/sbin/service "$SERVICE" start
}

force_reboot() {
    debug "reboot"

    # sync for 5 sec
    sync &
    sleep 5

    # force-restart server
    echo 1 > /proc/sys/kernel/sysrq
    echo b > /proc/sysrq-trigger
}

relive() {
    debug "relive started"
    logger -t apache-autorestart "relive started"

    echo "$(date -R)" | mailx -s "[apache-autorestart] relive started..." "$NOTIFY_EMAIL"

    # TOP 5 (ESTABLISHED) connections
    #netstat -ntp | tail -n +3 | grep "ESTABLISHED [0-9]\+/apache2" \
    netstat -ntp | tail -n +3 | grep " [0-9]\+/apache2" \
        | awk '{print $5}' | cut -d":" -f1 \
        | grep -v "127.0.0.1\|${SERVER}" \
        | sort | uniq -c | sort -n \
        | tail -n 5 >> "$LOG"

    # testing
    #exit 0

    # turn on swap
    /sbin/swapon -a

    # cron/1min = 3×2sec/repeat + 50sec/restart
    force_restart &  FR_PID=$!

    # kill force_restart after 50 seconds
    { sleep 50; kill -SIGKILL $FR_PID 2> /dev/null; } &  KID=$!

    # wait for force_restart
    wait $FR_PID

    # killing process killed force_restart -> force_restart failed
    if ! kill -0 $KID 2> /dev/null; then
        force_reboot
    fi

    # Apache relived
    exit 0
}

do_test() {
    # HTTP response time
    HTTP="$(/usr/local/bin/ncget-time.sh "$URL" 3> /dev/null 2>&1 1>&3 || echo "$ERROR")"
    [ -z "${HTTP//[0-9.]/}" ] || HTTP="$ERROR"
    [ "$HTTP" = "$ERROR" ] || HTTP=$(round "$HTTP")

    # apache processes
    PROCESS="$(apache_count)"

    # avgload %
    LOAD="$(cut -d' ' -f1 /proc/loadavg | bc || echo "$ERROR")"
    [ "$LOAD" = "$ERROR" ] || LOAD="$(round "100*$LOAD")"

    # high swap usage in MB
    SWAP="$(echo $(tail -n +2 /proc/swaps) | cut -d' ' -f4 || echo "$ERROR")"
    [ "$SWAP" = "$ERROR" ] || SWAP="$(round "$SWAP/1000")"

    # disk read in MB/sec
    TPUT="$(echo $(iostat -d -k xvda 2 2 | grep "^xvd" | tail -n 1) | cut -d' ' -f3 || echo "$ERROR")"
    [ "$TPUT" = "$ERROR" ] || TPUT="$(round "$TPUT/1000")"

    # testing - statistics for Excel importing
    #STATS="/root/log/apache-autorestart_$(date "+%Y-%m-%d").csv"
    #[ -f "$STATS" ] || echo -e "HTTP(sec);PROCESS;LOAD(%);SWAP(MB);TPUT(MB)\r" > "$STATS"
    #echo -e "$HTTP;$PROCESS;$LOAD;$SWAP;$TPUT\r" >> "$STATS"


    ERRORS="$(echo "$HTTP;$PROCESS;$LOAD;$SWAP;$TPUT" | grep -o "$ERROR" | wc -w)"
    [ "$ERRORS" -gt 1 ] && SCORE=$((SCORE+3))

    [ "$HTTP" = "$ERROR" ] || [ "$HTTP" -gt 2 ] && SCORE=$((SCORE+2))
    [ "$PROCESS" = "$ERROR" ] || [ "$PROCESS" -gt 75 ] && SCORE=$((SCORE+3))
    [ "$LOAD" = "$ERROR" ] || [ "$LOAD" -gt 100 ] && SCORE=$((SCORE+1))
    # on very high load add two
    [ "$LOAD" = "$ERROR" ] || [ "$LOAD" -gt 1000 ] && SCORE=$((SCORE+2))
    [ "$SWAP" = "$ERROR" ] || [ "$SWAP" -gt 900 ] && SCORE=$((SCORE+3))
    [ "$TPUT" = "$ERROR" ] || [ "$TPUT" -gt 5 ] && SCORE=$((SCORE+1))

    # testing
    #debug "test done, score=${SCORE}"
}


### MAIN ###

do_test

while [ $SCORE -ge 5 ]; do
    # we have high score
    REPEAT=$((REPEAT+1))
    debug "WARNING! score=${SCORE}, repeat=${REPEAT}"
    debug "H=${HTTP}; P=${PROCESS}; L=${LOAD}; S=${SWAP}; T=${TPUT}"

    # min 3 failures
    [ $REPEAT -ge 3 ] && relive

    SCORE=0
    do_test
done

