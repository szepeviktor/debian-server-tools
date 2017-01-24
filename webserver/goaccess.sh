#!/bin/bash
#
# Real-time web log analyzer.
#
# DEPENDS       :apt-get install goaccess
# VERSION       :0.1.4

U="$(stat . -c %U)"
#U="${1:-default-user}"

HTTPS="ssl-"

test -z "$IP" && exit 1

Goaccess() {
    goaccess \
        --ignore-crawlers \
        --agent-list \
        --http-method=yes \
        --all-static-files \
        --geoip-city-data=/var/lib/geoip-database-contrib/GeoLiteCity.dat \
        --log-format='%h %^[%d:%t %^] "%r" %s %b "%R" "%u"' \
        --date-format='%d/%b/%Y' \
        --time-format='%T' \
        --exclude-ip="$IP" \
        "$@"
}

Goaccess -f /var/log/apache2/${U}-${HTTPS}access.log

# List log files by size
# ls -lSr /var/log/apache2/*access.log

# Multiple log files (not realtime)
#cat /var/log/apache2/${U}-{ssl-,}access.log | Goaccess


# HTML output
#Goaccess -f /var/log/apache2/${U}-${HTTPS}access.log > /home/${U}/website/html/stat.html

# HTML output from multiple log files
#zcat /var/log/apache2/${U}-{ssl-,}access.log.{3,2}.gz | Goaccess > stat-30.html
#cat /var/log/apache2/${U}-{ssl-,}access.log{1,} | Goaccess > /home/${U}/website/html/stat.html
