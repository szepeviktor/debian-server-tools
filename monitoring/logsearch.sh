#!/bin/bash
#
# Smart search Apache logs.
#
# VERSION       :0.6.2
# DATE          :2015-04-27
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/logsearch.sh

# Set your log locations here
LOGS="/var/log/apache2/*access.log"
LOGS_OLD="/var/log/apache2/*access.log.1"
ERROR_LOGS="/var/log/apache2/*error.log"
ERROR_LOGS_OLD="/var/log/apache2/*error.log.1"
PIPE="cat"
FIELDS=""

#####################################################
# Parses out the version from a script
# Arguments:
#   FILE
#####################################################
Get_version() {
    local FILE="$1"
    local VER="$(grep -m1 "^# VERSION\s*:" "$FILE" | cut -d":" -f2-)"

    if [ -z "$VER" ]; then
        VER="(unknown)"
    fi
    echo "$VER"
}

##########################################################
# Show help
##########################################################
Usage() {
    cat <<EOF
logsearch v$(Get_version "$0")
Usage: $(basename "$0") [OPTION] [PATTERN]
Searches all Apache logs and displays selected log fields.

  -l                include log path
  -w                include log filename only (website)
  -d                include request date/time
  -i                include IP address
  -r                include the request line
  -n                include status code
  -f                include referer
  -u                include user agent
  -q                show only unique lines
  -s                numeric sort
  -t                sort by IP
  -c                show only line count
  -m                display the output by \`most\`
  -p                replace IP dots with \\.
  -o                parse previous logs (log.1)
  -e                parse error logs
  -x <FILE>         use the specified log file
  -h                display this help
EOF
    exit
}

##########################################################
# Add a log field to the output
# Globals:
#   FIELDS
# Arguments:
#   FIELD
##########################################################
Add_field() {
    local FIELD="$*"

    [ -z "$FIELDS" ] || FIELDS="${FIELDS}\t"
    FIELDS="${FIELDS}${FIELD}"
}

##########################################################
# Add to a list of commands through the log will be piped
# Globals:
#   PIPE
# Arguments:
#   CMD
##########################################################
Add_pipe() {
    local CMD="$*"

    [ -z "$PIPE" ] || PIPE="${PIPE}|"
    PIPE="${PIPE}${CMD}"
}

##########################################################

while getopts ":lwdirunfqstcmpoehx:" opt; do
    case $opt in
        l) # Log PATH
            Add_field "\1\/\2"
            ;;
        w) # Website name
            Add_field "\2"
            ;;
        d) # DATE
            Add_field "\4"
            ;;
        i) # IP
            Add_field "\3"
            ;;
        r) # REQUEST
            Add_field "\5"
            ;;
        n) # HTTP status code
            Add_field "\6"
            ;;
        f) # REFERER
            Add_field "\7"
            ;;
        u) # UA
            Add_field "\8"
            ;;
        q)
            Add_pipe "uniq -c"
            ;;
        s)
            Add_pipe "sort -n"
            ;;
        t)
            Add_pipe "sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n"
            ;;
        c)
            Add_pipe "wc -l"
            ;;
        m)
            Add_pipe "most"
            ;;
        p)
            IP_DOTS="1"
            ;;
        o)
            LOGS="${LOGS_OLD}"
            ERROR_LOGS="${ERROR_LOGS_OLD}"
            ;;
        e)
            ERRORLOG="1"
            ;;
        x)
            LOGS="$OPTARG"
            ;;
        h)
            Usage
            ;;
        \?)
            echo "Invalid option: -${OPTARG}" 1>&2
            Usage
            ;;
        :)
            echo "Option -${OPTARG} requires an argument." 1>&2
            Usage
            ;;
    esac
done

shift $((OPTIND - 1))

# What left is the search phrase
SEARCH="$*"
[ "${IP_DOTS}" == 1 ] && SEARCH="$(sed 's|\.|\\.|g' <<< "$SEARCH")"

# Default fields = all
[ -z "$FIELDS" ] && FIELDS="\1\/\2\t\3\t\4\t\5\t\6\t\7\t\8"

# access      222.255.28.000 - - [25/May/2014:06:54:27 +0200] "HEAD /siv/siv.zip HTTP/1.1" 200 294 "-" "-"
# error       [Sun Jul 13 12:00:51 2014] [error] [client 192.99.200.213] File does not exist: /home/user/public_html

if [ -z "$ERRORLOG" ]; then
    # Process access logs
    # shellcheck disable=SC2086
    grep "${SEARCH}" ${LOGS} \
        | sed 's/^\([^:]*\)\/\([^\/]*\):\([0-9a-f:\.]*\) .* .* \(\[.*\]\) "\(.*\)" \(.*\) .* "\(.*\)" "\(.*\)"$/'"$FIELDS"'/' \
        | eval "$PIPE"
else
    # Process error logs
    # Remove: 6, 7, 8
    FIELDS="${FIELDS//\\6/}"
    FIELDS="${FIELDS//\\7/}"
    FIELDS="${FIELDS//\\8/}"
    # Swap: 3 <-> 4
    FIELDS="${FIELDS//\\3/\X}"
    FIELDS="${FIELDS//\\4/\3}"
    FIELDS="${FIELDS//\\X/\4}"
    #             log path:1,2          date:4                        IP:3               message:5
    # shellcheck disable=SC2086
    grep -- "${SEARCH}" ${ERROR_LOGS} \
        | sed 's/^\([^:]*\)\/\([^\/]*\):\(\[.*\]\) \[error\] \[client \([0-9a-f:\.]*\)\] \(.*\)$/'"$FIELDS"'/' \
        | eval "$PIPE"
fi
