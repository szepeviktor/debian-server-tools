#!/bin/bash
#
# Help schedule maintenance between two Pingdom checks.
#
# VERSION       :0.1.3
# DATE          :2017-05-17
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/maintenance5.sh

# Start in the background:
#    maintenance5.sh &

# EDIT here
PINGDOM_ACCESS_LOG="/var/log/apache2/PROJECT-ssl-access.log"

Warn_minute()
{
    local NUMBER="$1"

    # Display minutes remaining
    printf '<%s>' "$NUMBER" 1>&2
    # Bell!
    printf '\a'
}

set -e

# Wait for Pingdom bot visit
sed -n -e '/"Pingdom\.com_bot_version_/q' <(tail -n 0 -f "$PINGDOM_ACCESS_LOG")

# We expect Pingdom bot to come back in 5 minutes
for M in {5..1}; do
    Warn_minute "$M"
    # Wait for a short minute
    sleep 59
done
Warn_minute 0
