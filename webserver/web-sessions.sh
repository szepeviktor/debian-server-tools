#!/bin/bash
#
# Display current web sessions.
#

ACCESS_LOG="/var/log/apache2/project-ssl-access.log"
SERVER_IP="1.2.3.4"

declare -i SESSION_MAX_LENGTH="600"

Exclude() {
    local IP="$1"
    local UA="$2"
    local REQUEST="$3"

    test "$IP" == "$SERVER_IP" && return 0
    test "$UA" == "Amazon CloudFront" && return 0
    test "$UA" == "HetrixTools.COM Uptime Monitoring Bot. https://hetrixtools.com/uptime-monitoring-bot.html" && return 0

    # Search bots
    [[ "$IP" =~ ^66\.249\.[6789] ]] && [ "$UA" != "${UA/ Googlebot\//}" ] && return 0
    [[ "$IP" =~ ^66\.249\.[6789] ]] && [ "$UA" != "${UA/\"Googlebot-Image\//}" ] && return 0
    [ "$UA" != "${UA/ AdsBot-Google-Mobile/}" ] && return 0
    [ "$UA" != "${UA/ facebookexternalhit\//}" ] && return 0
    [ "$UA" != "${UA/ bingbot\//}" ] && return 0
    [ "$UA" != "${UA/ Yahoo\! Slurp/}" ] && return 0
    [ "$UA" != "${UA/ Baiduspider\//}" ] && return 0
    [ "$UA" != "${UA/ YandexBot\//}" ] && return 0
    [ "$UA" != "${UA/ AhrefsBot\//}" ] && return 0
    [ "$UA" != "${UA/ DotBot\//}" ] && return 0
    [ "$UA" != "${UA/ spbot\//}" ] && return 0
    [ "$UA" != "${UA/ seoscanners.net\//}" ] && return 0
    [ "$UA" != "${UA/ MJ12bot\//}" ] && return 0

    return 1
}

Waiting() {
    while :; do
        sleep 0.5; echo -n "."
        sleep 0.5; echo -n "."
        sleep 0.5; echo -n "."
        sleep 0.5; echo -e -n "\r   \r"
    done
}

Display_sessions() {
    local ID
    local GEO
    local PTR
    local REQUEST

    for ID in "${SESSIONS[@]}"; do
        GEO="$(geoiplookup -f /var/lib/geoip-database-contrib/GeoLiteCity.dat "${SESSION_DATA[${ID}_IP]}" | cut -d ":" -f 2- | cut -c 1-30)"
        if [ "${GEO/N\/A,/}" != "$GEO" ]; then
            PTR="$(host -t PTR "${SESSION_DATA[${ID}_IP]}")"
            if [ $? -eq 0 ]; then
                GEO="${PTR#* domain name pointer }"
            fi
        fi
        REQUEST="${SESSION_DATA[${ID}_REQUEST]}"
        if [ ${#REQUEST} -gt 53 ]; then
            REQUEST="${REQUEST:0:20}...${REQUEST:(-30)}"
        fi
        # TAB separated
        echo "${SESSION_DATA[${ID}_IP]}	${GEO}	${REQUEST}	${SESSION_DATA[${ID}_UA]:0:60}"
    done
}

Session_gc() {
    local -i NOW
    local -i EXPIRATION
    local -i INDEX
    local ID

    NOW="$(date "+%s")"
    EXPIRATION="$((NOW - SESSION_MAX_LENGTH))"

    for INDEX in "${!SESSIONS[@]}"; do
        ID="${SESSIONS[$INDEX]}"
        if [ "${SESSION_DATA[${ID}_TIME]}" -lt "$EXPIRATION" ]; then
            # Destroy session
            unset SESSIONS[$INDEX]
            unset SESSION_DATA["${ID}_IP"]
            unset SESSION_DATA["${ID}_UA"]
            unset SESSION_DATA["${ID}_REQUEST"]
            unset SESSION_DATA["${ID}_TIME"]
        fi
    done
}

Session_exists() {
    local QUERY="$1"
    local ID

    for ID in "${SESSIONS[@]}"; do
        if [ "$ID" == "$QUERY" ]; then
            return 0
        fi
    done

    return 1
}

declare -a SESSIONS
declare -A SESSION_DATA

Waiting &
while read -r LOG_LINE; do
    IP="$(cut -d " " -f 1 <<< "$LOG_LINE")"
    UA="$(cut -d '"' -f 6 <<< "$LOG_LINE")"
    REQUEST="$(cut -d '"' -f 2 <<< "$LOG_LINE")"

    if Exclude "$IP" "$UA" "$REQUEST"; then
        continue
    fi

    ID="$(md5sum <<< "${IP}|${UA}" | cut -d " " -f 1)"
    APACHE_TIME="$(sed -n -e 's|^.* \[\([0-9]\+\)/\(\S\+\)/\([0-9]\+\):\([0-9]\+\):\([0-9]\+\):\([0-9]\+\) .*$|\1 \2 \3 \4:\5:\6|p' <<< "$LOG_LINE")"
    TIME="$(date --date "$APACHE_TIME" "+%s" 2> /dev/null)"
    # If time parsing fails
    if [ -z "$TIME" ]; then
        TIME="$(date "+%s")"
    fi

    # New session
    if ! Session_exists "$ID"; then
        SESSIONS+=( "$ID" )
        SESSION_DATA[${ID}_IP]="$IP"
        SESSION_DATA[${ID}_UA]="$UA"
    fi
    SESSION_DATA[${ID}_REQUEST]="$REQUEST"
    SESSION_DATA[${ID}_TIME]="$TIME"
    #echo "ID=${ID} #${#SESSIONS[*]} => ${SESSIONS[*]}"

    jobs -p | xargs -r kill -s SIGTERM
    clear
    #                  TAB separated
    Display_sessions | column -s "	" -t -c "$COLUMNS"
    Waiting &

    # Run gc in 1:10 chance
    if [ "$RANDOM" -lt 3276 ]; then
        Session_gc
    fi
done < <(tail -f "$ACCESS_LOG")
