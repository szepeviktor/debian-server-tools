tickets
-------

? IP config, static/DHCP

? use GPT partition table
? image with sysvinit (no systemd)
? Ubuntu image
? time synchronization to hypervisor, no ntpd (tsc_mode=2)
http://xenbits.xen.org/docs/4.3-testing/misc/tscmode.txt
? Will there be PV guests?

? local services: DNS resolver, email forwarding for monitoring, NTP=179.43.191.2
? default PTR: IPhex.client.privatelayer.com
? docs on gateway IP
? docs on our images

- Cloud init metadata server 169.254.169.254
- debian:privatel5

New
===

? entropy source (rng)
