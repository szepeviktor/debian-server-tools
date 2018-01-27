#!/usr/bin/python3

# -*- coding: utf-8 -*-
import sys
import geoip2.database as geoip
import socket


# https://pypi.python.org/pypi/geoip2

GEOIP2_CITY = "/var/lib/GeoIP/GeoLite2-City.mmdb"


def main(ip):
    if not ip:
        return

    reader = geoip.Reader(GEOIP2_CITY)

    response = reader.city(ip)
    reader.close()

    if response.subdivisions.most_specific.name:
        city = response.subdivisions.most_specific.name
    else:
        host = "N/A"
        try:
            (host, _, _) = socket.gethostbyaddr(ip)
        except socket.error:
            pass
        city = host

    print("%s, %s" % (response.country.iso_code, city))

if __name__ == "__main__":
    if len(sys.argv) == 2:
        main(sys.argv[1])
