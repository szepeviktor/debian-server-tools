#!/bin/bash
#
# Multiply stdin to any number of commands.
#
# VERSION       :0.1.2
# DATE          :2015-11-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/multi-stdout.sh

# Usage
#
#     ls -l | multi-stdout.sh "cat" "tac"

# At least two commands are necessary
if [ $# -lt 2 ]; then
    exit 1
fi

TEMPFILE="$(mktemp)"
# shellcheck disable=SC2064
trap "rm -f '$TEMPFILE'" EXIT HUP INT QUIT PIPE TERM

# Save stdin
cat > "$TEMPFILE"

while [ $# -gt 0 ]; do
    # No quotes around $1
    $1 < "$TEMPFILE"

    # Remember status of the last command
    RETCODE="$?"

    # Next command
    shift
done

# Exit with the status of the last command
exit "$RETCODE"
