# Monitoring

### Datasheets

- Server ([server.yaml](/debian-setup/server.yml))
- Website ([hosting.yaml](/webserver/hosting.yml))
- Project readme ([Project.md](/webserver/Project.md))
- PHP extensions ([php-env-check.php](/webserver/php-env-check.php))

### Per website and dependency monitoring

- DNS resource records ([dns-watch.sh](/monitoring/dns-watch.sh), [dnsspy.io](https://dnsspy.io/))
- HTTP message body (aka HTML source code)
- Visual change ([visualping.io](https://visualping.io/))
- HTTPS certificate and SSL settings ([ssl-check.sh](/monitoring/ssl-check.sh), [ssllabs.com](https://www.ssllabs.com/ssltest/), [Cryptosense](https://discovery.cryptosense.com/))
- File changes ([tripwire-fake.sh](/monitoring/tripwire-fake.sh))
- Application log ([laravel-report.sh](https://github.com/szepeviktor/running-laravel/blob/master/bin/laravel-report.sh))
- Malware listing ([sitecheck.sucuri.net](https://sitecheck.sucuri.net/), [Unmask Parasites](https://www.unmaskparasites.com/))
- PageSpeed ([PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/), [webpagetest.org](https://www.webpagetest.org/))
- Health ([Google Search Console](https://www.google.com/webmasters/tools/) aka Webmaster Tools)
- Traffic ([goaccess.sh](/monitoring/goaccess.sh), [HEAP](https://heapanalytics.com/), [Google Analytics](https://analytics.google.com/analytics/web/))
- Report JavaScript, PHP (and other) errors [Sentry](https://docs.sentry.io/server/installation/),
  client [for browsers](https://github.com/getsentry/sentry-javascript/tree/develop/packages/browser)
  and [for Laravel](https://github.com/getsentry/sentry-laravel)
  on CDN [with cross-origin resource sharing](https://blog.sentry.io/2016/05/17/what-is-script-error)
- Uptime ([monit](/monitoring/monit/services),
  [pingdom.com](https://www.pingdom.com/),
  [hetrixtools.com](https://hetrixtools.com/),
  [selectel.com](https://docs.selectel.com/cloud-services/monitoring/description/),
  [Oh Dear!](https://ohdearapp.com/))
- Dependencies: listed in [hosting.yaml](/webserver/hosting.yml)
- Dependencies: OCSP response ([ocsp-check.sh](/monitoring/ocsp-check.sh))

Alternatives for error reporting: [Bugsnag](https://www.bugsnag.com/),
[Rollbar](https://rollbar.com/),
[Raygun](https://raygun.com/),
http://jserrlog.appspot.com/ , https://github.com/mperdeck/jsnlog.js ,
https://github.com/errbit/errbit , https://github.com/airbrake/airbrake-js ,
[Google Analytics](https://developers.google.com/analytics/devguides/collection/analyticsjs/exceptions)

### Per host monitoring

- RTC, entropy, server integrity ([monit](/monitoring/monit/services))
- Datacenter: gateway, DNS resolvers ([monit](/monitoring/monit/services))
- All processes: binary, functional test, rc script, init script, log ([monit](/monitoring/monit/services))
- Cron jobs ([cron-grandchild.sh](/monitoring/cron-grandchild.sh), [cron-long.sh](/monitoring/cron-long.sh))
- Custom kernel updates ([ovh-kernel-update.sh](/security/ovh-kernel-update.sh))
- ICMP response ([monit](/monitoring/monit/services))
- SSH port ([ssh-watch.sh](/monitoring/ssh-watch.sh), [monit](/monitoring/monit/services))
- SMTP port ([monit](/monitoring/monit/services))
- MySQL table corruption and optimization
- SSL certificates in responses ([ssl-check.sh](/monitoring/ssl-check.sh))
- SSL certificate files ([cert-expiry.sh](/monitoring/cert-expiry.sh))
- Apache logs ([apache-4xx-report.sh](/monitoring/apache-4xx-report.sh), [apache-xreport.sh](/monitoring/apache-xreport.sh))
- File changes ([siteprotection.sh](/monitoring/siteprotection.sh))
- Errors in syslog ([syslog-errors.sh](/monitoring/syslog-errors.sh))
- RBL - DNS blacklists ([hetrixtools.com](https://hetrixtools.com/), [RBLTracker](https://rbltracker.com/), [RBLmon](https://www.rblmon.com/))
- Email deliverability ([can-send-email.sh](/monitoring/cse))
- Recipient domain and DNS
- TOP 10 mailfolders ([top10-mailfolders.sh](/monitoring/top10-mailfolders.sh))
- S.M.A.R.T. attributes ([smart-zeros.sh](/monitoring/smart-zeros.sh))
- Traffic spikes: HTTP, SMTP
- Uptime ([monit](/monitoring/monit/services), [healthchecks.io](https://healthchecks.io/))
- Performance graphs ([munin](/monitoring/munin))

### Per domain monitoring

- Domain locking ([Cloudflare Domain Security](https://www.cloudflare.com/domain-security-check/))
- Domain expiry ([domain-expiry.sh](/monitoring/domain-expiry.sh))
- RBL - DNS blacklists

### Monitoring of 3rd-parties

- Google Analytics JavaScript
- Cloudflare IP ranges
- URIBL IP address

### Performance tools

https://web.archive.org/web/20220120175537/http://www.perf-tooling.today/tools

### Search for errors in a log file

```bash
grep -Ei -B 1 -A 1 "crit|err[^u]|warn|fail[^2]|alert|unknown|unable|miss|except|disable|invalid|cannot|denied|broken|exceed|unsafe|unsolicited" \
    /var/log/dmesg
grep -Ei -B 1 -A 1 "crit|err[^u]|warn|fail[^2]|alert|unknown|unable|miss|except|disable|invalid|cannot|denied|broken|exceed|unsafe|unsolicited" \
    /var/log/syslog
```

See [/monitoring/syslog-errors.sh](/monitoring/syslog-errors.sh)

### Logging in syslog-style

Syslog time format: `date "+%b %e %T"`

Log to syslog: `echo MESSAGE | logger --tag "${TAG}[${PID}]"`

Log to anywhere else: `echo MESSAGE | sed -e "s|^|${TAG}[${PID}]: |" | ts "%b %e %T"`

### Courier log analyizer

```bash
courier-analog --smtpinet --smtpitime --smtpierr --smtpos --smtpod --smtpof \
    --imapnet --imaptime --imapbyuser --imapbylength --imapbyxfer \
    --noisy --noise=2 --title="TITLE" /var/log/mail.log
```

### Remove server from Munin monitoring

```bash
editor /etc/munin/munin.conf

read -r -p "Host name: " DOMAIN
ls /var/lib/munin/
rm -rfI /var/lib/munin/${DOMAIN}
ls /var/cache/munin/www/
rm -rfI /var/cache/munin/www/${DOMAIN}
```

### Detect virtualization technology

- http://git.annexia.org/?p=virt-what.git;a=summary
- http://www.freedesktop.org/software/systemd/man/systemd-detect-virt.html

```bash
apt-get install -y virt-what systemd dmidecode
virt-what
systemd-detect-virt -c; systemd-detect-virt -v
dmidecode -s system-product-name
```

### SMS sending

- https://textlocal.com/
- https://www.messagebird.com/
- https://www.twilio.com/

### Hurrican electric routers

```bash
wget -qO- "http://lg.he.net/" | sed -n -e 's|.*title="\([^"]\+\)".*>\(.\+\)<span>\([^<]\+\S\)\s*<.*|- \1 *\2* @ \3|p'
```

1. 184.105.223.234
1. 184.105.223.237
1. 62.115.49.169
1. 62.115.49.170

- core2.abq1.he.net - ABQIX *H5 Data Centers ABQ 1 * @ Albuquerque, NM, US
- core1.ash1.he.net - Equinix Ashburn, MegaIX Ashburn, DACS-IX East *Equinix Ashburn (DC2) * @ Ashburn, VA, US
- core2.atl1.he.net - Digital Realty Atlanta IX (Telx-TIE) *Digital Realty / Telx Atlanta (ATL1), 56 Marietta * @ Atlanta, GA, US
- core1.atl2.he.net - CIX-ATL *CoreSite AT1 * @ Atlanta, GA, US
- core1.aus1.he.net - FD-IX Texas *Switch Data Foundry 01 * @ Austin, TX, US
- core2.blp1.he.net *Zayo NP MSP1 * @ Belle Plaine, MN, US
- core1.boi1.he.net *Involta * @ Boise, ID, US
- core2.bos1.he.net - Boston IX *One Summer Boston * @ Boston, MA, US
- core1.bos2.he.net - MASS-IX *CoreSite BO1 * @ Boston, MA, US
- core1.buf1.he.net *365 Data Centers BU1 * @ Buffalo, NY, US
- core2.yyc1.he.net - YYCIX *Datahive Calgary * @ Calgary, AB, CA
- core1.crw1.he.net *Alpha Technologies DC1 * @ South Charleston, WV, US
- core2.clt1.he.net *Lumos / DC74 Data Center CLT-2 Charlotte * @ Charlotte, NC, US
- core2.cys1.he.net *ACT Cheyenne * @ Cheyenne, WY, US
- core1.chi1.he.net - Equinix Chicago, AMS-IX Chicago, ChIX *Equinix Chicago (CH1/CH2) * @ Chicago, IL, US
- core3.chi1.he.net - Equinix Chicago, AMS-IX Chicago, ChIX *Equinix Chicago (CH1/CH2) * @ Chicago, IL, US
- core1.chi3.he.net - Any2 Chicago *CoreSite Chicago * @ Chicago, IL, US
- core1.cvg1.he.net *CyrusOne CIN2 * @ Cincinnati, OH, US
- core1.cle1.he.net - Midwest-IX Cleveland *H5 Data Centers CLE 1 * @ Cleveland, OH, US
- core2.cmh1.he.net - Ohio IX *Cologix Columbus * @ Columbus, OH, US
- core3.dal1.he.net - Equinix Dallas, CyrusOne, MegaIX Dallas *Equinix Dallas (DA1) * @ Dallas, TX, US
- core4.dal1.he.net - Equinix Dallas, CyrusOne, MegaIX Dallas *Equinix Dallas (DA1) * @ Dallas, TX, US
- core1.dal2.he.net *Cologix DAL1 * @ Dallas, TX, US
- core1.dvn1.he.net - QCIX *SFN IA * @ Davenport, IA, US
- core2.den1.he.net - Any2 Denver, IX-Denver *CoreSite Denver * @ Denver, CO, US
- core1.den3.he.net *910Telecom * @ Denver, CO, US
- core1.dsm1.he.net - DesMoinesIX *Connect * @ Des Moines, IA, US
- core2.det1.he.net - DET-IX *123NET Detroit * @ Southfield, MI, US
- core1.ewr4.he.net *Iron Mountain NJE-1 * @ Edison, NJ, US
- core2.yeg1.he.net - YEGIX *Wolfpaw * @ Edmonton, AB, CA
- core1.far1.he.net - FMIX *702 Communications * @ Fargo, ND, US
- core3.fmt1.he.net *Hurricane Electric Fremont 1 * @ Fremont, CA, US
- core1.fmt2.he.net - FCIX, SFMIX, AMS-IX Bay Area, Lambda-IX *Hurricane Electric Fremont 2 * @ Fremont, CA, US
- core6.fmt2.he.net - FCIX, SFMIX, AMS-IX Bay Area, Lambda-IX *Hurricane Electric Fremont 2 * @ Fremont, CA, US
- core1.yhz1.he.net - HFXIX *EXA * @ Halifax, NS, CA
- core1.pdx2.he.net *EdgeConneX POR01 * @ Hillsboro, OR, US
- core2.hnl1.he.net - DRF IX *DRFortress Honolulu * @ Honolulu, HI, US
- core2.hou1.he.net *Consolidated Houston * @ Houston, TX, US
- core2.hou2.he.net - HOUIX *Netrality 1301 Fannin Houston * @ Houston, TX, US
- core2.ind1.he.net - MidWest-IX Indy *Netrality IND / Lifeline Henry Street * @ Indianapolis, IN, US
- core2.jax1.he.net - JXIX *GoRack 421 * @ Jacksonville, FL, US
- core1.jax2.he.net *Cologix JAX1 * @ Jacksonville, FL, US
- core2.mci1.he.net *Lumen / Level3 * @ Kansas City, MO, US
- core3.mci3.he.net - KCIX *1102 Grand Kansas City * @ Kansas City, MO, US
- core1.las1.he.net - Vegas-IX *Fiberhub Las Vegas * @ Las Vegas, NV, US
- core2.lax1.he.net - Equinix Los Angeles, LAIIX, MegaIX Los Angeles *Equinix Los Angeles (LA1) * @ Los Angeles, CA, US
- core3.lax2.he.net - Any2 West, NYIIX Los Angeles, BBIX Los Angeles *CoreSite One Wilshire * @ Los Angeles, CA, US
- core4.lax2.he.net - Any2 West, NYIIX Los Angeles, BBIX Los Angeles *CoreSite One Wilshire * @ Los Angeles, CA, US
- core2.msn1.he.net - MadIX *5NINES Madison * @ Madison, WI, US
- core1.mnz1.he.net *Iron Mountain VA-1 * @ Manassas, VA, US
- core1.mht1.he.net *Crown Castle One Sundial * @ Manchester, NH, US
- core1.mfe1.he.net - MEX-IX *McAllen Data Centers * @ McAllen, TX, US
- core2.mia1.he.net - FL-IX, Equinix Miami *Equinix MI1 Miami * @ Miami, FL, US
- core2.msp1.he.net - MICE *Cologix Minneapolis * @ Minneapolis, MN, US
- core1.mso1.he.net *iConnect Missoula * @ Missoula, MT, US
- core2.yqm1.he.net *Fibre Centre Moncton * @ Moncton, NB, CA
- core1.mgm1.he.net - MGMix Montgomery *RSA Dexter Montgomery * @ Montgomery, AL, US
- core1.ymq1.he.net - QIX Montreal *Cologix Montreal / CANIX 3 * @ Montreal, QC, CA
- core2.bna1.he.net - NashIX *365 Data Centers NA1 * @ Nashville, TN, US
- core1.nyc1.he.net *Webair NY1 * @ Garden City, NY, US
- core1.nyc3.he.net *Digital Realty NYC3 (32 AofA) * @ New York, NY, US
- core2.nyc4.he.net - Equinix New York *Equinix New York (NY9) * @ New York, NY, US
- core3.nyc4.he.net - Equinix New York *Equinix New York (NY9) * @ New York, NY, US
- core2.nyc5.he.net - Digital Realy New York IX (Telx-TIE) *Digital Realty / Telx New York (NYC1), 60 Hudson * @ New York, NY, US
- core1.nyc6.he.net - DE-CIX NY, NYIIX *Telehouse New York, Chelsea * @ New York, NY, US
- core1.nyc7.he.net *Digital Realty / Telx 111 8th New York * @ New York, NY, US
- core1.nyc8.he.net *CoreSite NY1 * @ New York, NY, US
- core1.nyc9.he.net *Telehouse Teleport Center * @ New York, NY, US
- core2.ewr1.he.net *165 Halsey MMR - Tishman * @ Newark, NJ, US
- core1.mci4.he.net - GPC Missouri *NOCIX 1530 Swift * @ North Kansas City, MO, US
- core2.okc1.he.net - iX-OKC *RACK59 Data Center * @ Oklahoma City, OK, US
- core2.oma1.he.net - OmahaIX *1623 Farnam Omaha * @ Omaha, NE, US
- core1.orl1.he.net *CoreSite OR1 * @ Orlando, FL, US
- core1.yow1.he.net - OGIX *PureColo * @ Ottawa, ON, CA
- core2.pao1.he.net - Equinix Palo Alto, NASA-AIX *Equinix Palo Alto (SV8) * @ Palo Alto, CA, US
- core2.phl1.he.net *Equinix Philadelphia (PH1) * @ Philadelphia, PA, US
- core2.phx1.he.net - Digital Realty Phoenix Internet Exchange. *Digital Realty / Telx Phoenix (PHX1), 120 E Van Buren * @ Phoenix, AZ, US
- core1.phx2.he.net - Phoenix IX, DE-CIX Phoenix *PhoenixNAP * @ Phoenix, AZ, US
- core1.ewr3.he.net *QTS Data Centers PNJ1 * @ Piscataway, NJ, US
- core1.pit1.he.net - PIT-IX  *DataBank PIT1 * @ Pittsburgh, PA, US
- core2.pdx1.he.net - NWAX *Pittock Building Portland * @ Portland, OR, US
- core1.pdx3.he.net *Flexential PDX02 Hillsboro 2 * @ Hillsboro,  OR, US
- core1.pwm1.he.net - NNENIX *Firstlight Fiber Regen Hut * @ Portland, ME, US
- core1.pwm2.he.net *Deep Edge PWM * @ Portland, ME, US
- core1.yqb1.he.net *Vantage * @ Quebec City, QC, CA
- core2.rno1.he.net - TahoeIX *Roller Network Reno * @ Reno, NV, US
- core1.ric1.he.net - DE-CIX Richmond *Pixel Factory * @ Ashland, VA, US
- core1.rst1.he.net *Zayo NP * @ Rochester, MN, US
- core1.rut1.he.net *VELCO VT1 * @ Rutland, VT, US
- core1.sac1.he.net *NTT / RagingWire CA1 * @ Sacramento, CA, US
- core2.slc1.he.net - MWestIX, SLIX *Databank / C7 Salt Lake City * @ Salt Lake City, UT, US
- core1.sat1.he.net - SAT-IX *H5 Data Centers SAT 1 * @ San Antonio, TX, US
- core2.sfo1.he.net - SFMIX *Digital Realty / Telx (SFR1) San Francisco * @ San Francisco, CA, US
- core3.sjc1.he.net - AMS-IX Bay Area *CoreSite SV1 / Hurricane Electric San Jose 1 * @ San Jose, CA, US
- core3.sjc2.he.net - Equinix San Jose *Equinix San Jose (SV1) * @ San Jose, CA, US
- core4.sjc2.he.net - Equinix San Jose *Equinix San Jose (SV1) * @ San Jose, CA, US
- core2.yxe1.he.net - YXEIX *University of Saskatchewan * @ Saskatoon, SK, CA
- core2.sea1.he.net - Equinix Seattle, MegaIX Seattle, SIX *Equinix Seattle (SE2), Westin Building * @ Seattle, WA, US
- core1.sea2.he.net *Westin Building MMR * @ Seattle, WA, US
- core1.ewr2.he.net *Equinix NY5 * @ Secaucus, NJ, US
- core1.fsd1.he.net *SDN Communications * @ Sioux Falls, SD, US
- core1.ska1.he.net - SpokaneIX *Neutron * @ Spokane, WA, US
- core2.stl1.he.net - MidWest-IX STL, STLIX *Netrality 210 N Tucker St. Louis * @ St. Louis, MO, US
- core2.tpa1.he.net - TPAIX *365 Data Centers TA1 * @ Tampa, FL, US
- core2.tor1.he.net - Equinix Toronto, MegaIX Toronto, TorIX, ONIX *Equinix Toronto (TR1) * @ Toronto, ON, CA
- core1.tor2.he.net *Cologix Toronto * @ Toronto, ON, CA
- core2.yvr1.he.net *Cologix Vancouver * @ Vancouver, BC, CA
- core1.yvr2.he.net - CSIX, UNM-Exch Canada-West, VANIX *Harbour Centre MMR * @ Vancouver, BC, CA
- core1.orf1.he.net *Globalinx * @ Virginia Beach, VA, US
- core1.orf2.he.net *Telxius * @ Virginia Beach, VA, US
- core1.ewr5.he.net *NJFX * @ Wall, NJ, US
- core2.ywg1.he.net - MBIX, WPGIX *Global Server Center * @ Winnipeg, MB, CA
- core2.ams1.he.net - AMS-IX, Asteroid Amsterdam IX, Frys-IX, LSIX, SPEED-IX, ERA-IX *NIKHEF Amsterdam * @ Amsterdam, NL
- core1.ams2.he.net - NL-IX, Equinix Amsterdam *Equinix AM7 * @ Amsterdam, NL
- core1.ams3.he.net *Interxion AMS8 * @ Rozenburg, NL
- core1.ams4.he.net *Equinix AM3 * @ Amsterdam, NL
- core1.ams5.he.net *Interxion AMS9 * @ Amsterdam, NL
- core1.ams7.he.net *Iron Mountain AMS-1 * @ Haarlem, NL
- core1.ams8.he.net *Digital Realty AMS17 (Science Park) * @ Amsterdam, NL
- core1.ath1.he.net - GR-IX Athens, SEECIX *Lamda Hellix * @ Koropi, GR
- core2.bcn1.he.net - CATNIX, DE-CIX Barcelona, Equinix Barcelona *Equinix BA1 * @ Barcelona, ES
- core2.beg1.he.net - SOX Serbia *CETIN / Telenor * @ Belgrade, RS
- core2.ber1.he.net - BCIX, ECIX-BER *IPB CarrierColo Berlin * @ Berlin, DE
- core3.ber1.he.net - BCIX, ECIX-BER *IPB CarrierColo Berlin * @ Berlin, DE
- core1.bio1.he.net *Telxius Derio Hub * @ Derio, ES
- core2.bts1.he.net - NIX.SK, SIX.SK *Sitel * @ Bratislava, SK
- core2.bru1.he.net - BelgiumIX, BNIX *Interxion Brussels * @ Zaventem, BE
- core2.buh1.he.net - InterLAN, RONIX, Balcan-IX *NXDATA-1 * @ Bucharest, RO
- core2.bud1.he.net - BIX Budapest *Victor Hugo 1 * @ Budapest, HU
- core1.bud2.he.net *Dataplex * @ Budapest, HU
- core2.cph1.he.net - DIX, Netnod Copenhagen, STHIX Copenhagen *Interxion Copenhagen * @ Copenhagen, DK
- core2.dus1.he.net - ECIX Dusseldorf, DE-CIX Dusseldorf *Interxion Dusseldorf * @ Düsseldorf, DE
- core2.dub1.he.net - INEX LAN1, INEX LAN2 *Equinix Dublin (DB2) * @ Dublin, IE
- core2.edi1.he.net - LINX Scotland *Pulsant Edinburgh South Gyle * @ Edinburgh, UK
- core3.fra1.he.net - DE-CIX Frankfurt, KleyRex, LocIX Frankfurt, STACIX *Interxion Frankfurt * @ Frankfurt, DE
- core3.fra2.he.net - Equinix Frankfurt, ECIX Frankfurt *Equinix Frankfurt (FR1) * @ Frankfurt, DE
- core1.fra3.he.net *Equinix FR2 * @ Frankfurt, DE
- core2.gva1.he.net - CIXP *Equinix Geneva (GV1) * @ Geneva, CH
- core2.ham1.he.net - BREM-IX, DE-CIX Hamburg, ECIX Hamburg *GlobalConnect HAM2 * @ Hamburg, DE
- core1.ktw1.he.net *4 Data Center * @ Katowice, PL
- core1.kbp1.he.net - DTEL-IX, GigaNET, UA-IX, PITER-IX Kyiv, 1-IX *NewTelco Ukraine * @ Kyiv, UA
- core1.lba1.he.net - IX Leeds, IXBradford *aql Salem Church * @ Leeds, UK
- core1.lis1.he.net - GigaPix, Equinix Lisbon *Equinix LS1 * @ Lisbon, PT
- core3.lon1.he.net - LoNAP *Telehouse Docklands East * @ London, UK
- core2.lon2.he.net - LINX LON1, Equinix London *Equinix London (LD8) * @ London, UK
- core3.lon2.he.net - LINX LON1, Equinix London *Equinix London (LD8) * @ London, UK
- core2.lon3.he.net *Telehouse Docklands North * @ London, UK
- core1.lon6.he.net *Interxion LON1 * @ London, UK
- core1.lon7.he.net *Global Switch * @ London, UK
- core1.lon9.he.net *Iron Mountain LON-1 * @ Slough, UK
- core2.lux1.he.net - LU-CIX *LuxConnect DC1.1 * @ Bettembourg, LU
- core1.mad1.he.net - ESPANIX Lower, ESPANIX Upper, DE-CIX Madrid, IXPlay Madrid *Interxion Madrid * @ Madrid, ES
- core2.man1.he.net - LINX Manchester, Equinix Manchester *Equinix MA1 * @ Manchester, UK
- core4.mrs1.he.net - France-IX Marseille, DE-CIX Marseille *Interxion Marseille * @ Marseille, FR
- core2.muc1.he.net - DE-CIX Munich, ECIX Munich *Equinix Munich (MU1) * @ München, DE
- core2.mil1.he.net *MIX Milan Via Caldera * @ Milan, IT
- core2.mil2.he.net - MIX, MINAP Milan, TOP-IX, Equinix Milan *Enter Milan * @ Milan, IT
- core2.osl1.he.net - FIXO, NIX Oslo *STACK Infrastructure / Digiplex Norway * @ Oslo, NO
- core2.par1.he.net *Interxion Paris 2 * @ Paris, FR
- core2.par2.he.net - France-IX Paris, LU-CIX *Telehouse Paris Voltaire * @ Paris, FR
- core2.par3.he.net - Equinix Paris *Equinix Paris (PA2) * @ Paris, FR
- core2.prg1.he.net - NIX.CZ, Peering.cz *CE Colo Prague * @ Prague, CZ
- core2.rix1.he.net - SMILE-LV, PITER-IX Riga *LVRTC TV Tower * @ Riga, LV
- core1.rom1.he.net - NaMeX *NaMeX Rome * @ Roma, IT
- core1.skp1.he.net - IXP.mk *Telesmart DC Skopje * @ Skopje, MK
- core1.lon5.he.net *Equinix LD5 * @ Slough, UK
- core3.sof1.he.net - BIX.BG, B-IX, NetIX, MegaIX Sofia, T-CIX *Telepoint Colocation * @ Sofia, BG
- core3.sto1.he.net - NetNod-A, NetNod-B, SOLIX, STHIX, Global-IX, DataIX, DataIX-2 *Equinix Stockholm (SK1) * @ Stockholm, SE
- core2.tll1.he.net - MSK-IX, RTIX, TLLIX, PITER-IX Tallinn *Elion Tallinn * @ Tallinn, EE
- core1.tia1.he.net - ANIX *ANIX * @ Tirana, AL
- core2.vie1.he.net - VIX *Interxion Vienna * @ Vienna, AT
- core2.vno1.he.net - BALT-IX, LIXP Vilnius *Data Logistics Center * @ Vilnius, LT
- core2.waw1.he.net - Equinix Warsaw (PLIX), POZIX, THINX Warsaw, TPIX Warsaw, IX.LODZ.PL *Equinix WA1 Warsaw, 1-IX EU * @ Warsaw, PL
- core2.zag1.he.net - CIX *University of Zagreb, University Computing Centre SRCE * @ Zagreb, HR
- core1.zag2.he.net *Interxion ZAG1 / Altus IT * @ Zagreb, HR
- core2.zrh2.he.net - CHIX-CH *Interxion ZUR1 * @ Glattbrugg, CH
- core2.zrh3.he.net - Equinix Zurich, SwissIX *Equinix Zürich (ZH4) * @ Zurich, CH
- core1.akl1.he.net - AKL-IX, APE, MegaIX Auckland *DataCentre220 * @ Auckland, NZ
- core1.akl2.he.net *Vocus Albany * @ Auckland, NZ
- core1.bne1.he.net - EdgeIX Brisbane, MegaIX Brisbane, QLD-IX *NEXTDC B1 * @ Brisbane, AU
- core1.gum1.he.net - MARIIX *UoG - Office of Information Technology * @ Mangilao, UOG STATION, GU
- core1.mel2.he.net *NEXTDC M1 * @ Melbourne, AU
- core1.per1.he.net - EdgeIX Perth, IX Australia WA, MegaIX Perth *NEXTDC P1 * @ Malaga, AU
- core1.mel1.he.net - EdgeIX Melbourne, Equinix Melbourne, MegaIX Melbourne, VIC-IX Melbourne *Equinix ME1 * @ Melbourne, AU
- core2.syd1.he.net - EdgeIX Sydney, Equinix Sydney, IX Australia NSW, MegaIX Sydney, CON-IX Brisbane *Equinix SY1 * @ Sydney, AU
- core1.syd3.he.net *NEXTDC S1 * @ Sydney, AU
- core1.bkk1.he.net - BKNIX *TCC Technology Bangna * @ Bangkok, TH
- core1.hkg1.he.net - AMS-IX HK, HKIX, IAIX, BBIX Hong Kong *MEGA-iAdvantage Hong Kong * @ Hong Kong, HK
- core2.hkg2.he.net - Equinix Hong Kong, Megaport Hong Kong *Equinix Hong Kong (HK1) * @ Hong Kong, HK
- core1.kul1.he.net - CSL Thai-IX Malaysia, DE-CIX Kuala Lumpur, MyIX *AIMS * @ Kuala Lumpur, MY
- core1.mnl2.he.net - GetaFIX Manila *PLDT VITRO Makati 1 * @ Makati, PH
- core2.osa1.he.net - BBIX Osaka, JPNAP Osaka, JPIX Osaka *Equinix Osaka (OS1) * @ Osaka, JP
- core1.pnh1.he.net - CNX *Sabay MNV * @ Phnom Penh, KH
- core2.sel1.he.net - KINX *KINX Seoul * @ Seoul, KR
- core1.sel2.he.net - Equinix Seoul *Equinix SL1 * @ Seoul, KR
- core2.sin1.he.net - AMS-IX Singapore, BBIX Singapore, EdgeIX Singapore, Equinix Singapore, MegaIX Singapore, DE-CIX ASEAN/JBIX, SGIX *Equinix Singapore (SG1) * @ Singapore, SG
- core2.tpe1.he.net - STUIX, TPIX Taiwan *Chief LY Building * @ Taipei, TW
- core3.tyo1.he.net - BBIX Tokyo, Equinix Tokyo, JPNAP Tokyo, JPIX Tokyo *Equinix Tokyo (TY2) * @ Tokyo, JP
- core2.bog1.he.net *Equinix BG1 * @ Bogota, CO
- core1.for1.he.net *GlobeNet * @ Fortaleza, BR
- core1.rio1.he.net - IX.br (PTT.br) Rio de Janeiro, Equinix Rio de Janeiro *Equinix RJ2 * @ Rio de Janeiro, BR
- core3.sao1.he.net - IX.br (PTT.br) Sao Paulo, Equinix Sao Paulo *Equinix Sao Paulo (SP2) * @ São Paulo, BR
- core1.bue1.he.net - n/a *SYT Buenos Aires * @ Buenos Aires, AR
- core1.cpt1.he.net - NAPAfrica Cape Town, CINX *Teraco CT1 * @ Cape Town, WC, ZA
- core1.jib1.he.net - DjIX *Djibouti Data Center * @ Djibouti City, DJ
- core1.dur1.he.net - DINX, NAPAfrica IX Durban *Teraco DB1 * @ Durban, ZA
- core2.jnb1.he.net - NAPAfrica Johannesburg, JINX *Teraco JB1 * @ Johannesburg, GP, ZA
- core1.los1.he.net - AF-CIX, IXPN Lagos *Rack Centre * @ Lagos, NG
- core1.mba1.he.net *icolo.io Mombasa One * @ Mombasa, KE
- core1.nbo1.he.net - KIXP Nairobi *Africa Data Centres NBO1 * @ Nairobi, KE
- core1.dxb1.he.net - UAE-IX *Equinix Dubai (DX1) * @ Dubai, AE
- core1.ist1.he.net - DE-CIX Istanbul, GIBIRIX *Equinix IL2 * @ Istanbul, TR
