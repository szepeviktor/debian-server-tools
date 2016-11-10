# Global networking tools

[Timing details with curl](https://blog.josephscott.org/2011/10/14/timing-details-with-curl/)

### Target country speed test

- speedtest-cli 100+
- `netselect-apt -c hu stable`
- Cachefly CDN http://cachefly.cachefly.net/100mb.test

- Keycdn IPv6 https://tools.keycdn.com/ipv6-ping `P`
- Aruba.cz http://speedtest.forpsi.net/ `PTS6`
- Aruba.cz http://29.209.forpsi.net/ `PTS6`
- OVH 3 http://ipv4.rbx.proof.ovh.net/ `PTS`
- OVH weathermap http://weathermap.ovh.net/strasbourg-1
- OVH datacenters http://travaux.ovh.net/vms/index_sbg1.html
- Digital Ocean 9 http://speedtest-ams3.digitalocean.com/ `PTS`
- Linode 6 https://www.linode.com/speedtest `PTS`
- VPS.NET http://cloudtestfiles.net/ `PTS`
- Vultr 10 http://www.ssdpromocode.com/vultr-locations-test `PTS`
    - http://fra-de-ping.vultr.com/ping.php?host=8.8.8.8
    - http://fra-de-ping.vultr.com/trace.php?host=8.8.8.8
    - http://fra-de-ping.vultr.com/vultr.com.100MB.bin

    1. ams-nl-ping.vultr.com
    1. fra-de-ping.vultr.com
    1. ga-us-ping.vultr.com
    1. hnd-jp-ping.vultr.com
    1. lax-ca-us-ping.vultr.com
    1. lon-gb-ping.vultr.com
    1. nj-us-ping.vultr.com
    1. par-fr-ping.vultr.com
    1. syd-au-ping.vultr.com
    1. wa-us-ping.vultr.com

- Cloud Monitor 50+ https://asm.ca.com/en/ping.php `PT`
- gtt 40+ http://www.as3257.net/lg/ `PTB`
- SdV 4 http://bgpmap.sdv.fr/index.php `PTB`
- HE http://lg.he.net/ `PTB`
- TATA (de) http://lg.as6453.net/bin/lg.cgi `PTB`
- LOCAPING 10 http://www.locaping.com/ `PT`
- pingdom 1×Sweden http://tools.pingdom.com/ping/ `PT`
- http://www.super-ping.com/ `PT`
- http://startping.com/ `P`
- RIPE https://stat.ripe.net/widget/bgplay `B` https://stat.ripe.net/widget/list
- RIPEstat https://stat.ripe.net/ ``B
- https://www.peeringdb.com/login.php
- BIX http://www.bix.hu/lg/lg.cgi `PTB6`
- HBONE http://diag.vh.hbone.hu/lookingglass/lg.cgi `PTB6`
- HBONE http://diag.vh.hbone.hu/mtr/ `PT6`

### Hungarian speedtests

- http://www.speedtest.net/
- http://speedtest.upc.hu/
- http://speedtest6.digi.hu/
- http://www.sebessegteszt.telekom.hu/
- http://speedtest.datanet.hu/
- https://www.externet.hu/index.php/ugyintezes/sebessegmeres
- http://speedtest.szelessavkereso.hu/index.nof?parent=http%3A%2F%2Fwww.szelessavindex.hu%2FSzelessav_speedtest.nof

### IX locations

- http://espanix.eu/en/noticias.html
- https://www.euro-ix.net/users/sign_up
- http://www.bgp4.as/looking-glasses

##### Legend

`P` - ping
`T` - traceroute
`S` - speedtest
`B` - BGP
`6` - IPv6
