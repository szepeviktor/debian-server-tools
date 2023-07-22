#!/bin/bash

# Log only
SECS=5
# Mobile client open more than 20 sockets
HITS=40

# APPEND after other rules ->  don't log blocked traffic
iptables -A INPUT -p tcp -m multiport --dports 80,443 -i eth0 -m state --state NEW \
    -m recent --set
iptables -A INPUT -p tcp -m multiport --dports 80,443 -i eth0 -m state --state NEW \
    -m recent --update --seconds "$SECS" --hitcount "$HITS" -j LOG --log-prefix "HTTP flood: " --log-level 4

# Output of `iptables -S`
#
#    iptables -A INPUT -i eth0 -p tcp -m multiport --dports 80,443 -m state --state NEW \
#        -m recent --set --name DEFAULT --rsource
#    iptables -A INPUT -i eth0 -p tcp -m multiport --dports 80,443 -m state --state NEW \
#        -m recent --update --seconds 5 --hitcount 40 --name DEFAULT --rsource -j LOG --log-prefix "HTTP flood: "

exit 0

# Ban
iptables -N LOGGING
iptables -A INPUT -j LOGGING

iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPtables-Dropped: " --log-level 4
iptables -A LOGGING -j DROP

iptables -A INPUT -p tcp -m multiport --dports 80,443 -i eth0 -m state --state NEW \
    -m recent --update --seconds "$SECS" --hitcount "$HITS" -j DROP


# monitor:

#!/bin/bash

LOGFILE="/var/log/messages"

grep "^$(LC_ALL=C date --date="1 day ago" "+%b %e ")" "$LOGFILE" \
    | grep -o '\bHTTP flood: .*' \
    | cut -d " " -f 6 | uniq -c \
    | grep -v '^\s\+[0-9] ' \
    | mail -E -S from="apache floods <root>" -s "[ad.min] Apache floods on $(hostname -f)" webmaster


# high:

grep -o '\bHTTP flood: .*' /var/log/messages \
    | cut -d " " -f 6 | uniq -c \
    | grep -E -v '^\s+[0-9]{1,2} '
