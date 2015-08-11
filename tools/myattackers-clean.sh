#!/bin/bash
#
# Generate removal commands for old MYATTACKERS rules without traffic.
#

# Usage
#
#     myattackers-clean.sh | bash

# List rules
#   only old (20+ line number) rules without traffic
#   begin at the end
#   print command
iptables --line-numbers -n -v -L MYATTACKERS \
    | sed -n '22,$s/^\([0-9]\+\)\s\+0\s\+0\s\+DROP\s.*$/\1/p' \
    | sort -r -n \
    | xargs -r -L1 echo iptables -v -D MYATTACKERS
