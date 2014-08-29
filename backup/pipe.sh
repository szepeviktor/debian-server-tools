#!/bin/bash
#
# Send (pipe) files through a TCP socket AES256 encrypted.
#
# VERSION       :0.2
# DATE          :2014-08-29
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# LOCATION      :/usr/local/bin/pipe.sh
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install netcat aespipe gzip bzip2 xz-utils


## Example ~/.pipe config
#
#  # host and port name of the receiver
#  PIPE_SERVER="domain.net"
#  PIPE_PORT="12345"
#  # tar compression type: z,j,J
#  PIPE_COMPRESSION="z"
#  # AES password $(pwgen -s -y 30 1)
#  PIPE_PASSWORD="hD2wsRa^BYFh@=87xXQT{[f3QNKQlN"

## Usage
#
#  Example #1: send files, receive files
#  host1 $ pipe.sh put file1.jpg file2.zip
#                               host2 $ pipe.sh get
#
#  Example #2: send stream, receive stream into a file
#  host1 $ ls -lR | pipe.sh put
#                               host2 $ pipe.sh get dir-list.txt


CONF=~/.pipe
[ -r "$CONF" ] && . "$CONF"

CMD="$1"
shift

# port from config
[ -z "$PIPE_PORT" ] && exit 1
# compression from config
[ -z "$PIPE_COMPRESSION" ] && exit 2
PIPE_COMPRESSION="${PIPE_COMPRESSION:0:1}"
[ -z "${PIPE_COMPRESSION/[zjJ]}" ] || exit 3
# password from config
[ -z "$PIPE_PASSWORD" ] && exit 4

pipe_get() {
    local OUTPUT="$1"

    if [ -z "$OUTPUT" ]; then
        # receive files
        nc -l -p "$PIPE_PORT" -vv | aespipe -d -e AES256 -p 3 3<<< "$PIPE_PASSWORD" \
            | tar x"$PIPE_COMPRESSION"v
    else
        # receive stream and pipe to $OUTPUT
        [ -d "$OUTPUT" ] && exit 4

        case "$PIPE_COMPRESSION" in
            z)
                nc -l -p "$PIPE_PORT" -vv | aespipe -d -e AES256 -p 3 3<<< "$PIPE_PASSWORD" \
                    | gunzip > "$OUTPUT"
                ;;
            j)
                nc -l -p "$PIPE_PORT" -vv | aespipe -d -e AES256 -p 3 3<<< "$PIPE_PASSWORD" \
                    | bunzip2 > "$OUTPUT"
                ;;
            J)
                nc -l -p "$PIPE_PORT" -vv | aespipe -d -e AES256 -p 3 3<<< "$PIPE_PASSWORD" \
                    | unxz > "$OUTPUT"
                ;;
        esac
    fi
}

pipe_put() {
    [ -z "$PIPE_SERVER" ] && exit 11

    if [ -z "$*" ] || [ "$*" = - ]; then
        # send stream
        case "$PIPE_COMPRESSION" in
            z)
                gzip | aespipe -e AES256 -p 3 3<<< "$PIPE_PASSWORD" \
                    | nc -q 1 -vv "$PIPE_SERVER" "$PIPE_PORT"
                ;;
            j)
                bzip2 | aespipe -e AES256 -p 3 3<<< "$PIPE_PASSWORD" \
                    | nc -q 1 -vv "$PIPE_SERVER" "$PIPE_PORT"
                ;;
            J)
                xz | aespipe -e AES256 -p 3 3<<< "$PIPE_PASSWORD" \
                    | nc -q 1 -vv "$PIPE_SERVER" "$PIPE_PORT"
                ;;
        esac
    else
        # send files
        ls "$@" &> /dev/null || exit 12
        tar -c"$PIPE_COMPRESSION"v "$@" | aespipe -e AES256 -p 3 3<<< "$PIPE_PASSWORD" \
            | nc -q 1 -vv "$PIPE_SERVER" "$PIPE_PORT"
    fi
}

#####################################################

which nc aespipe xz gzip bzip2 > /dev/null || exit 99

case "$CMD" in
    get)
        # receive through TCP socket
        pipe_get "$1"
        ;;
    put)
        # send through TCP socket
        pipe_put "$@"
        ;;
    *)
        # usage
        echo "$0 get|put [<file(s)>]" >&2
        exit
        ;;
esac

if [ $? = 0 ]; then
    echo "Piping OK."
else
    echo "Piping ERROR!"
fi
