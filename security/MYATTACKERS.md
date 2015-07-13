# List of attackers

## Attacker types

- HTTP Known vulnerability scanners
- HTTP "nofollow" and hidden form field violators
- HTTP WordPress login attackers (brute force)
- SMTP Authentication attackers (dictionary attack)
- SMTP Spammers see: ${D}/mail/spammer.dnsbl/
- SSH  Authentication attackers
- SSH  Known vulnerability scanners
- Mixed

```
# HU SpyderNet Kft. http://bgp.he.net/AS29278#_prefixes
# type: HTTP - HDB2 bot
# type: SMTP - broken pipe, ?HTTP commands in SMTP
217.113.54.0/24

# NL/RU HOSTKEY-NET http://bgp.he.net/AS57043#_prefixes
# DC: Serverius
# aliases: Mir Telematiki
5.39.216.0/21
#31.192.109.0/24
#31.192.110.0/24
#46.17.96.0/21
#46.249.38.0/24
146.0.72.0/21
#185.70.184.0/22
193.109.68.0/23
195.162.68.0/23
# Mir Telematiki Ltd. http://bgp.he.net/AS49335#_prefixes
# 8 prefixes: 141.105.64.0 - 141.105.71.255
141.105.64.0/21
# 8 prefixes: 158.255.0.0 - 158.255.7.255
158.255.0.0/21

# OVH dedicated servers http://bgp.he.net/AS16276#_prefixes
5.135.160.0/19
37.59.0.0/18
37.187.0.0/19
46.105.96.0/19
87.98.128.0/18
91.121.0.0/16
192.99.0.0/16
142.4.192.0/19

# FR ONLINE S.A.S. http://bgp.he.net/AS12876#_prefixes
# DC: Iliad Entreprises
# aliases: poneytelecom.eu, scaleway cloud
# IE-POOL-BUSINESS-HOSTING
62.210.0.0/16
# FR-ILIAD-ENTREPRISES-CUSTOMERS
195.154.0.0/17

# NL Ecatel http://bgp.he.net/AS29073#_prefixes
# type: SSH
# type: HTTP
80.82.64.0/20
93.174.88.0/21

# CHINANET-SH
50.200.243.136
116.224.0.0/12
223.4.0.0/14

# HEETHAI-HK
103.41.124.0/24
103.41.125.0/24

# Linkpad spider @Leaseweb http://bgp.he.net/AS60781#_prefixes
# type: HTTP
85.17.73.171
85.17.73.172

# Microsoft
# type: SSH
137.135.0.0/16
```

### Set up MYATTACKERS chain

```bash
iptables -N MYATTACKERS
iptables -I INPUT -j MYATTACKERS
iptables -A MYATTACKERS -j RETURN
```

For management scripts see: $D/tools/deny-ip.sh

#### HTTP on SMTP in syslog

```
courieresmtpd: error,relay=::ffff:1.2.3.4,msg="502 ESMTP command error",cmd: GET / HTTP/1.0
courieresmtpd: error,relay=::ffff:1.2.3.4,msg="502 ESMTP command error",cmd: HOST: @@SERVER-IP@@
courieresmtpd: error,relay=::ffff:1.2.3.4,msg="writev: Broken pipe",cmd: HOST: @@SERVER-IP@@
```
