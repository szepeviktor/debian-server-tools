#!/bin/bash
#
# Multiply stdin to any number of commands.
#
# VERSION       :0.1.1
# DATE          :2015-08-06
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/multi-stdout.sh

# Usage
#
#     ls -l | /usr/local/bin/multi-stdout.sh "cat" "tac"

# At lease two commands are necessary
[ $# -lt 2 ] && exit 1

TEMPFILE="$(mktemp)"
trap "rm -f '$TEMPFILE'" EXIT

# Save stdin
cat > "$TEMPFILE"

while [ $# -gt 0 ]; do
    # No quotes around $1
    $1 < "$TEMPFILE"

    # Return the exit code of the last command
    RETCODE="$?"

    # Next command
    shift
done

# Clean up
exit "$RETCODE"
