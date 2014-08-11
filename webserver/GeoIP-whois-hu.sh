#!/bin/bash
#
# Generate an Apache config file to allow access only from Hungary
#
# VERSION       :0.2
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/GeoIP-whois-hu.sh
# DEPENDS       :apt-get install wget unzip
# DEPENDS       :/usr/local/bin/range2cidr.awk


OUT="./GeoIPhuWhois.txt"
OUT2="./ip.ludost.txt"


######### Maxmind ###############

if ! [ -f GeoIPCountryWhois.csv ]; then
    wget -q http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip
    unzip GeoIPCountryCSV.zip > /dev/null
fi

echo '<Files wp-login.php>
# GeoLite data created by MaxMind
# http://dev.maxmind.com/geoip/legacy/geolite/
  order deny,allow
  deny from all' > "$OUT"

grep ',"HU",' GeoIPCountryWhois.csv \
    | cut -d"," -f1,2 | sed 's|^"\(.*\)","\(.*\)"$|\1 \2|' \
    | while read range; do
        range2cidr.awk $range | while read r2; do
            echo "  Allow from $r2" >> "$OUT"
        done
     done

######### ludost ###############

echo '<Files wp-login.php>' > "$OUT2"

wget -qO - --post-data="country=1&country_list=hu&format_template=apache-allow&format_name=&format_target=&format_default=" \
    https://ip.ludost.net/cgi/process >> "$OUT2"

########## both ############

echo '</Files>' | tee -a "$OUT2" >> "$OUT"

