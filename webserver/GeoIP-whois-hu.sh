#!/bin/bash
#
# Generate an Apache config file to allow access only from Hungary
#
# VERSION       :0.3.1
# DATE          :2015-08-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install unzip
# DEPENDS       :/usr/local/bin/range2cidr.awk
# LOCATION      :/usr/local/bin/GeoIP-whois-hu.sh

MAXMIND="./hu-GeoIP.conf"
LUDOST="./hu-ip.ludost.conf"

# Maxmind
if [ ! -f ./GeoIPCountryWhois.csv ]; then
    wget -nv "https://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip"
    unzip -q GeoIPCountryCSV.zip
fi
{
    echo "<Files wp-login.php>"
    echo "  # GeoLite data created by MaxMind"
    echo "  # https://dev.maxmind.com/geoip/legacy/geolite/"
    sed -n -e 's/^"\([0-9.]\+\)","\([0-9.]\+\)","[0-9]\+","[0-9]\+","HU",".*"$/\1 - \2/p' GeoIPCountryWhois.csv \
        | xargs -r -L 1 /usr/local/bin/range2cidr.awk \
        | sed -e 's/^/  Require ip /'
    echo "</Files>"
} >"$MAXMIND"

# ludost - seems to be more up-to-date
{
    echo "<Files wp-login.php>"
    wget -qO- --post-data="country=1&country_list=hu&format_template=apache-allow&format_name=&format_target=&format_default=" \
        "https://ip.ludost.net/cgi/process" \
        | sed -e 's/  allow from /  Require ip /' -e '/^  order deny,allow$/d' -e '/^  deny from all$/d'
    echo "</Files>"
} >"$LUDOST"
