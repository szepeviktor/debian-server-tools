#!/bin/bash
#
# Help schedule maintenance between two Pingdom checks.
#
# VERSION       :0.1.1
# DATE          :2017-05-17
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/maintenance5.sh

# Start in the background:
#    maintenance5.sh &

PINGDOM_ACCESS_LOG="/var/log/apache2/artmedic-hu-access.log"

Warn_minute() {
    local NUMBER="$1"

    # Display minutes remaining
    echo -n "<${NUMBER}>" 1>&2
    echo -en "\a"
}

set -e

# Wait for Pingdom bot visit
tail -n 0 -f "$PINGDOM_ACCESS_LOG" | sed -n -e '/"Pingdom\.com_bot_version_/q'

# We expect Pingdom bot to come back in 5 minutes
for N in {5..1}; do
    Warn_minute "$N"
    # Wait for a short minute
    sleep 59
done
Warn_minute 0
