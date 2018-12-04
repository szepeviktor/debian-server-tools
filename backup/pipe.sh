#!/bin/bash
#
# Send (pipe) files through a TCP socket AES256 encrypted.
#
# VERSION       :0.3.1
# DATE          :2015-10-07
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install netcat aespipe gzip bzip2 xz-utils
# CONFIG        :~/.pipe
# LOCATION      :/usr/local/bin/pipe.sh

# Example configuration
#     # Host and port name of the sender
#     PIPE_SERVER="domain.net"
#     PIPE_PORT="12345"
#     # Compression type for tar: z,j,J
#     PIPE_COMPRESSION="z"
#     # AES password $(apg -a 1 -M LCNS -m 30 -n 1)
#     PIPE_PASSWORD='hD2wsRa^BYFh@=87xXQT{[f3QNKQlN'
#
# Usage
# Sender listens on the specified port,
# the receiver connects to the sender's open port.
#
# Example #1
# Send files from host1, receive files on host2.
#     user@host1:~$ pipe.sh put file1.jpg file2.zip
#     user@host2:~$ pipe.sh get
#
# Example #2
# Send stream from host1, receive stream into a file on host2.
#     user@host1:~$ ls -lR | pipe.sh put
#     user@host2:~$ pipe.sh get dir-list.txt

Pipe_get()
{
    local OUTPUT="$1"

    if [ -z "$OUTPUT" ]; then
        # Receive files
        nc --recv-only -vv "$PIPE_SERVER" "$PIPE_PORT" \
            | aespipe -d -e AES256 -p 3 3<<<"$PIPE_PASSWORD" | tar xv"$PIPE_COMPRESSION"
    else
        # Receive stream and pipe to file
        test -d "$OUTPUT" && exit 4

        case "$PIPE_COMPRESSION" in
            z)
                COMPRESS="gunzip"
                ;;
            j)
                COMPRESS="bunzip2"
                ;;
            J)
                COMPRESS="unxz"
                ;;
        esac
        nc --recv-only -vv "$PIPE_SERVER" "$PIPE_PORT" \
            | aespipe -d -e AES256 -p 3 3<<<"$PIPE_PASSWORD" | "$COMPRESS"
    fi
}

Pipe_put()
{
    test -z "$PIPE_SERVER" && exit 11

    if [ -z "$*" ] || [ "$*" == "-" ]; then
        # Send stream
        case "$PIPE_COMPRESSION" in
            z)
                COMPRESS="gunzip"
                ;;
            j)
                COMPRESS="bunzip2"
                ;;
            J)
                COMPRESS="unxz"
                ;;
        esac
        "$COMPRESS" | aespipe -e AES256 -p 3 3<<<"$PIPE_PASSWORD" \
            | nc -l -p "$PIPE_PORT" -q 1 --send-only -vv
    else
        # Send files
        ls "$@" &>/dev/null || exit 12
        tar -cv"$PIPE_COMPRESSION" "$@" | aespipe -e AES256 -p 3 3<<<"$PIPE_PASSWORD" \
            | nc -l -p "$PIPE_PORT" -q 1 --send-only -vv
    fi
}

which nc aespipe xz gzip bzip2 &>/dev/null || exit 99

CONF="${HOME}/.pipe"
# shellcheck disable=SC1090
test -r "$CONF" && source "$CONF"

# Port from config
test -z "$PIPE_PORT" && exit 1
# Compression from config
test -z "$PIPE_COMPRESSION" && exit 2
PIPE_COMPRESSION="${PIPE_COMPRESSION:0:1}"
test -z "${PIPE_COMPRESSION/[zjJ]}" || exit 3
# Password from config
test -z "$PIPE_PASSWORD" && exit 4

CMD="$1"
shift

case "$CMD" in
    get)
        # Receive
        Pipe_get "$1"
        ;;
    put)
        # Send
        Pipe_put "$@"
        ;;
    *)
        # Usage
        echo "$0 get|put [<file(s)>]" 1>&2
        exit 0
        ;;
esac

# shellcheck disable=SC2181
if [ "$?" == 0 ]; then
    echo "Piping OK."
else
    echo 'Piping ERROR!'
fi
