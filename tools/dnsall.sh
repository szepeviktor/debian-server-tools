#!/bin/bash
#
# Look up an IP address on many open DNS recursive resolvers.
#
# DOCS          :https://www.publicdns.xyz/
# DOCS          :https://wiki.ipfire.org/dns/public-servers
# LOCATION      :/usr/local/bin/dnsall.sh

# Usage
#     dnsall.sh +all example.com. A | grep 'Query time:'

# @TODO: primary/secondary, IPv4/IPv6, DNSSEC, EDNS, malware filter, Anycast

Get_primary_ipv4()
{
    # CloudFlare
    # https://1.1.1.1/
    echo "1.1.1.1"
    # Google
    # https://developers.google.com/speed/public-dns/
    echo "8.8.8.8"
    # Level3 / CenturyLink
    # resolver1.level3.net.
    echo "209.244.0.3"
    # Hurricane Electric
    # ordns.he.net.
    echo "74.82.42.42"
    # DNS.WATCH
    # https://dns.watch/index
    echo "84.200.69.80"
    # OpenDNS Home
    # https://www.opendns.com/setupguide/
    echo "208.67.222.222"
    # Neustar (DNS Advantage)
    # https://www.security.neustar/digital-performance/dns-services/recursive-dns
    echo "156.154.70.5"
    # Norton ConnectSafe
    # "On November 15, 2018, Norton ConnectSafe service is being retired"
    # Dyn
    # https://dyn.com/labs/dyn-internet-guide/
    echo "216.146.35.35"
    # Verisign
    # https://www.verisign.com/en_US/security-services/public-dns/index.xhtml
    echo "64.6.64.6"
    # Quad9
    # https://www.quad9.net/microsoft/
    echo "9.9.9.9"
    # Comodo
    # https://www.comodo.com/secure-dns/
    echo "8.26.56.26"
    # SafeDNS
    # https://www.safedns.com/en/features/
    echo "195.46.39.39"
    # Yandex
    # https://dns.yandex.com/advanced/
    echo "77.88.8.8"
    # UncensoredDNS
    # https://blog.uncensoreddns.org/
    echo "91.239.100.100"
    # Freenom
    # https://www.freenom.world/
    echo "80.80.80.80"
}

Get_primary_ipv4 | xargs -t -I %% -- dig @%% "$@"
