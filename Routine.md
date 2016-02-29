# Routine for servers and websites

### Mail servers

- relay clients
- managed hosts
- incoming forwarded mail
- providers/can-send-email
- other subscriptions
- broken SMTP servers
- extra case
- hosts with broken STARTTLS

- user accounts, mailboxes
- transactional mail provider

### Weekly


- opcache/apc/memcache control panels

1. Domain expiry
    auto
1. DNS records
    auto
1. @TODO `monitoring/rbl-watch.sh`, [RBL blacklists monitoring](https://www.rblmon.com/), https://www.projecthoneypot.org/ (also for shared-hosting servers)
    auto
1. HTML source code inspection
    view-source:URL
1. Malware: [Sucuri SiteCheck (Safebrowsing)], [Virustotal URL]
    https://sitecheck.sucuri.net/results/DOMAIN
    https://www.virustotal.com/hu/domain/DOMAIN/information/
    @TODO Virustotal-API.py
1. Uptime: [Pingdom](https://www.pingdom.com/free/), `shared-hosting-aid/ping.php`
    auto
    
1. @TODO Detect JavaScript errors
  - Piwik
  - http://jserrlog.appspot.com/
  - https://github.com/mperdeck/jsnlog.js
  - https://developers.google.com/analytics/devguides/collection/analyticsjs/exceptions
  - https://github.com/errbit/errbit
  - https://github.com/airbrake/airbrake-js
1. Front page monitoring `monitoring/frontpage-check.sh`
1. Visual changes: https://visualping.io/ @TODO PhantomJS/slimerJS + `compare -metric MAE/PAE reference.png current.png`
1. File changes `lucanos/Tripwire`, `lasergoat/Tripwire` (rewrite)
1. Filter Apache error logs `monitoring/apache-xreport.sh` @TODO munin plugin: log size in lines
1. Monitor Apache error log `error-log-monitor` plugin on shared hosting, `shared-hosting-aid/remote-log-watch.sh` @TODO Remote rotate error.log
1. Connected services: trackers, API-s, CDN etc.
1. Email delivery, also recipient accounts: `can-send-email`
1. Also for email recipient domains: domain expiry, DNS, blacklist
1. Speed: https://developers.google.com/speed/pagespeed/insights/ , https://www.webpagetest.org/
1. Google Search Console
    https://www.google.com/webmasters/tools/dashboard?hl=en&siteUrl=ENCODED-URL
1. Traffic: Analytics
1. SEO ranking: SEO Panel


### Weekly per website

jumpstart.php?DOMAIN


1. check auto-s running
2. do manual-s

## üzemeltetés

1. ügyfeleknek szolg leírása en/hu
2. áttekintés/ütemezés magamnak
3. setup with snippets and links
4. pseudo script copy&paste

### szerver lista

- olé
- magyar hosting
- forpsi
- qupdate
- qss
- solidhosting openstack
- online.net (ARM)

### honlap lista

- ingyenesen üzemeltetett
- fizetős
- full service

## Szerver - kézi

- munin végignézés 'hét'
- wp-lib checksums, check-/yaml/root/config 'hét'
- biztonsági mentés

## Tárhely - kézi

- biztonsági mentés

## Szerver - autómata

- modmark
- package-versions.sh 'hó'
- vpscheck.sh 'nap'

## Tárhely - autómata

- -> shared-hosting-aid/README.md

## Honlap - kézi

- bővítmény frissítés (csoportosan)
- itsec log és error.log megnézés, törlés
- hozzászólások moderálása
- takarítás: transient, orphan post/comment/user-meta, media, post/page/comment trash
- MySQL táblák: check, optimize

# gyártás:
- szerver, honlap sqlite3 + listázó
- időzítő heti, havi
