#!/bin/bash
#
# Smart search Apache logs.
#
# VERSION       :0.5
# DATE          :2014-09-15
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/logsearch.sh
# STYLE         :https://google-styleguide.googlecode.com/svn/trunk/shell.xml


# put your log locations here
LOGS="/var/log/apache2/access*.log /home/*/log/access*.log"
LOGS_OLD="/var/log/apache2/access*.log.1 /home/*/log/access*.log.1"
ERROR_LOGS="/var/log/apache2/error*.log /home/*/log/error*.log"
ERROR_LOGS_OLD="/var/log/apache2/error*.log.1 /home/*/log/error*.log.1"
PIPE="cat"
FIELDS=""

#####################################################
# Parses out the version from a script
# Arguments:
#   FILE
#####################################################
get_version() {
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
usage() {
    cat << USAGE
logsearch v$(get_version "$0")
Usage: $(basename $0) [OPTION] [PATTERN]
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
USAGE
    exit
}

##########################################################
# Add a log field to the output
# Globals:
#   FIELDS
# Arguments:
#   FIELD
##########################################################
add_field() {
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
add_pipe() {
    local CMD="$*"

    [ -z "$PIPE" ] || PIPE="${PIPE}|"
    PIPE="${PIPE}${CMD}"
}

##########################################################

while getopts ":lwdirunfqstcmpoehx:" opt; do
    case $opt in
        l) # log PATH
            add_field "\1\/\2"
            ;;
        w) # website name
            add_field "\2"
            ;;
        d) # DATE
            add_field "\4"
            ;;
        i) # IP
            add_field "\3"
            ;;
        r) # REQUEST
            add_field "\5"
            ;;
        n) # HTTP status code
            add_field "\6"
            ;;
        f) # REFERER
            add_field "\7"
            ;;
        u) # UA
            add_field "\8"
            ;;
        q)
            add_pipe "uniq -c"
            ;;
        s)
            add_pipe "sort -n"
            ;;
        t)
            add_pipe "sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n"
            ;;
        c)
            add_pipe "wc -l"
            ;;
        m)
            add_pipe "most"
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
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

shift $((OPTIND-1))

# what left is the search phrase
SEARCH="$*"
[ "${IP_DOTS}" = 1 ] && SEARCH="$(sed 's|\.|\\.|g' <<< "$SEARCH")"

# default fields = all
[ -z "$FIELDS" ] && FIELDS="\1\/\2\t\3\t\4\t\5\t\6\t\7\t\8"

# access      222.255.28.000 - - [25/May/2014:06:54:27 +0200] "HEAD /siv/siv.zip HTTP/1.1" 200 294 "-" "-"
# error       [Sun Jul 13 12:00:51 2014] [error] [client 192.99.200.213] File does not exist: /home/user/public_html

if [ -z "$ERRORLOG" ]; then
    # process access logs
    grep "${SEARCH}" ${LOGS} \
        | sed 's/^\([^:]*\)\/\([^\/]*\):\([0-9a-f:\.]*\) .* .* \(\[.*\]\) "\(.*\)" \(.*\) .* "\(.*\)" "\(.*\)"$/'"$FIELDS"'/' \
        | eval "${PIPE}"

else
    # process error logs

    # remove: 6,7,8, 4 -> 3, 3 -> 4
    FIELDS="${FIELDS//\\6/}"
    FIELDS="${FIELDS//\\7/}"
    FIELDS="${FIELDS//\\8/}"
    FIELDS="${FIELDS//\\3/\X}"
    FIELDS="${FIELDS//\\4/\3}"
    FIELDS="${FIELDS//\\X/\4}"

    #             log path:1,2          date:4                        IP:3               message:5
    grep "${SEARCH}" ${ERROR_LOGS} \
        | sed 's/^\([^:]*\)\/\([^\/]*\):\(\[.*\]\) \[error\] \[client \([0-9a-f:\.]*\)\] \(.*\)$/'"$FIELDS"'/' \
        | eval "${PIPE}"
fi
