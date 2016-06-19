#!/bin/bash
#
# Real-time web log analyzer.
#

IP="$IP"
U="$(stat . -c %U)"

Goaccess() {
    goaccess \
        --agent-list
        --http-method=yes \
        --geoip-city-data=/var/lib/geoip-database-contrib/GeoLiteCity.dat \
        --log-format='%h %^[%d:%t %^] "%r" %s %b "%R" "%u"' \
        --date-format='%d/%b/%Y'
        --time-format='%T' \
        --exclude-ip="$IP" "$@"
}

# HTTPS
Goaccess -f /var/log/apache2/${U}-ssl-access.log
# HTTP
#Goaccess -f /var/log/apache2/${U}-access.log

# Multiple log files (not realtime)
#cat /var/log/apache2/${U}{-ssl,}-access.log | Goaccess

# HTML output
#Goaccess -f /var/log/apache2/${U}-ssl-access.log -o /home/${U}/website/html/stat.html
#Goaccess -f /var/log/apache2/${U}-access.log -o /home/${U}/website/html/stat.html

# HTML output from multiple log files
#cat /var/log/apache2/${U}{-ssl,}-access.log | Goaccess -o /home/${U}/website/html/stat.html
