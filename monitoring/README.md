# Monitoring

### Datasheets

- Server ([server.yaml](/server.yml))
- Website ([hosting.yaml](/webserver/hosting.yml))
- Project readme ([Project.md](/webserver/Project.md))
- PHP extensions ([php-env-check.php](/webserver/php-env-check.php))

### Per website and dependency monitoring

- DNS resource records ([dns-watch.sh](/monitoring/dns-watch.sh), [dnsspy.io](https://dnsspy.io/))
- HTTP message body (aka HTML source code)
- Visual change ([visualping.io](https://visualping.io/))
- HTTPS certificate and SSL settings ([ssl-check.sh](/monitoring/ssl-check.sh), [ssllabs.com](https://www.ssllabs.com/ssltest/), [Cryptosense](https://discovery.cryptosense.com/))
- File changes ([tripwire-fake.sh](/monitoring/tripwire-fake.sh))
- Application log ([laravel-report.sh](/monitoring/laravel-report.sh))
- Malware listing ([sitecheck.sucuri.net](https://sitecheck.sucuri.net/), [Unmask Parasites](https://www.unmaskparasites.com/))
- PageSpeed ([PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/), [webpagetest.org](https://www.webpagetest.org/))
- Health ([Google Search Console](https://www.google.com/webmasters/tools/) aka Webmaster Tools)
- Traffic ([goaccess.sh](/monitoring/goaccess.sh), [HEAP](https://heapanalytics.com/), [Google Analytics](https://analytics.google.com/analytics/web/))
- Report JavaScript, PHP (and other) errors [Sentry](https://docs.sentry.io/server/installation/),
  client [for browsers](https://github.com/getsentry/sentry-javascript/tree/master/packages/raven-js)
  and [for Laravel](https://github.com/getsentry/sentry-laravel)
  on CDN [with cross-origin resource sharing](https://blog.sentry.io/2016/05/17/what-is-script-error)
- Uptime ([monit](/monitoring/monit/services), [pingdom.com](https://www.pingdom.com/),
  [hetrixtools.com](https://hetrixtools.com/), [selectel.com](https://selectel.com/services/additional/monitoring/),
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

http://www.perf-tooling.today/tools

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

- https://www.textlocal.com/
- https://www.messagebird.com/
- https://www.twilio.com/

### Hurrican electric routers

```bash
wget -qO- "http://lg.he.net/" | sed -n -e 's|.*title="\([^"]\+\)".*>\(.\+\)<span>\([^<]\+\)<.*|- \1 *\2* @ \3|p'
```

1. 184.105.223.234
1. 184.105.223.237
1. 62.115.49.169
1. 62.115.49.170

- core1.ams1.he.net - AMS-IX, NL-IX, DF-IX, SPEED-IX, Asteroid Amsterdam IX *NIKHEF Amsterdam * @ Amsterdam, NL 
- core1.bcn1.he.net - CATNIX *Eqinix BA1, Barcelona * @ Barcelona, ES 
- core1.beg1.he.net - SOX Serbia *Telenor, Belgrade * @ Belgrade, RS 
- core1.ber1.he.net - BCIX, ECIX Berlin *IPB CarrierColo Berlin * @ Berlin, DE 
- core1.bts1.he.net - NIX.SK *Sitel, Bratislava * @ Bratislava, SK 
- core1.bru1.he.net - BNIX *Interxion Brussels * @ Zaventem, BE 
- core1.buh1.he.net - INTERLAN, RONIX, Balcan-IX *NXDATA-1, Bucharest * @ Bucharest, RO 
- core1.bud1.he.net - BIX Budapest *CE Colo Victor Hugo 1 * @ Budapest, HU 
- core1.cph1.he.net - DIX, Netnod Copenhagen *Interxion Copenhagen * @ Copenhagen, DK 
- core1.dus1.he.net - ECIX Dusseldorf, DE-CIX Dusseldorf *Interxion Dusseldorf * @ Düsseldorf, DE 
- core1.dub1.he.net - INEX *Equinix Dublin (DB2) * @ Dublin, IE 
- core1.fra1.he.net - DE-CIX Frankfurt, ECIX Frankfurt, KleyRex, DataIX *Interxion Frankfurt * @ Frankfurt, DE 
- core1.gva1.he.net - CIXP *Equinix Geneva (GV1) * @ Geneva, CH 
- core1.ham1.he.net - BREM-IX, DE-CIX Hamburg, ECIX Hamburg *GlobalConnect, Hamburg * @ Hamburg, DE 
- core1.hel1.he.net - FICIX, Equinix Helsinki *Digita Datacenter 2 * @ Helsinki, FI 
- core1.kbp1.he.net - DTEL-IX, GigaNET, UA-IX *NewTelco Ukraine * @ Kiev, UA 
- core1.lis1.he.net - GigaPix *Equinix LS1, Lisbon * @ Prior Velho, Lisbon, PT 
- core1.lon1.he.net - LoNAP *Telehouse Docklands East * @ London, UK 
- core1.lon2.he.net - LINX *Equinix London (LD8) * @ London, UK 
- core1.lon3.he.net - *Telehouse Docklands North * @ London, UK 
- core1.lux1.he.net - LU-CIX *LuxConnect DC1.1 * @ Bettembourg, LU 
- core1.mad1.he.net - ESPANIX, DE-CIX Madrid *Interxion Madrid * @ Madrid, ES 
- core1.man1.he.net - IXManchester *Equinix MA1, Manchester * @ Manchester, UK 
- core1.mrs1.he.net - France-IX Marseille, DE-CIX Marseille *Interxion Marseille * @ Marseille, FR 
- core1.muc1.he.net - DE-CIX Munich, ECIX Munich *Equinix Munich (MU1) * @ München, DE 
- core1.mil1.he.net - MIX, TOP-IX *MIX Milan Via Caldera * @ Milan, IT 
- core1.mil2.he.net - *Enter Milan * @ Milan, IT 
- core1.osl1.he.net - FIXO, NIX *Digiplex Norway, Oslo * @ Oslo, NO 
- core1.par1.he.net - *Interxion Paris 2 * @ Paris, FR 
- core1.par2.he.net - Equinix Paris, France-IX Paris, LU-CIX *Telehouse Paris Voltaire * @ Paris, FR 
- core1.prg1.he.net - NIX.CZ, Peering.CZ *CE Colo Prague * @ Prague, CZ 
- core1.rix1.he.net - SMILE-LV *LVRTC TV Tower * @ Riga, LV 
- core1.rom1.he.net - NaMeX *NaMeX * @ Roma, IT 
- core1.sof1.he.net - BIX.BG, B-IX, NetIX, OM-NIX, T-CIX *Telepoint Colocation, Sofia * @ Sofia, BG 
- core1.sto1.he.net - NetNod-A, NetNod-B, SOLIX, STHIX, Global-IX *Equinix Stockholm (SK1) * @ Stockholm, SE 
- core1.tll1.he.net - RTIX, TLLIX *Elion Tallinn * @ Tallinn, EE 
- core1.vie1.he.net - VIX *Interxion Vienna * @ Vienna, AT 
- core1.vno1.he.net - LIXP Vilnius *Data Logistics Center * @ Vilnius, LT 
- core1.waw1.he.net - POZIX, PLIX, THINX, EPIX Katowice, EPIX Warsaw, TPIX Warsaw *Equinix / Telecity Warsaw * @ Warsaw, PL 
- core1.zag1.he.net - CIX *University of Zagreb, University Computing Centre SRCE * @ Zagreb, HR 
- core1.zrh2.he.net - *Interxion ZUR1, Zurich * @ Glattbrugg, CH 
- core1.zrh3.he.net - Equinix Zurich, SwissIX *Equinix Zürich (ZH4) * @ Zurich, CH 
- core1.ash1.he.net - Equinix Ashburn, MegaIX Ashburn *Equinix Ashburn (DC2) * @ Ashburn, VA, US 
- core1.atl1.he.net - Digital Realty Atlanta IX (Telx-TIE), CIX-ATL *Digital Realty / Telx Atlanta (ATL1), 56 Marietta * @ Atlanta, GA, US 
- core1.blp1.he.net - *Neutral Path MSP1, Belle Plaine * @ Belle Plaine, MN, US 
- core1.bos1.he.net - Boston Internet Exchange, Mass IX *One Summer Boston * @ Boston, MA, US 
- core1.yyc1.he.net - YYCIX *Datahive Calgary * @ Calgary, AB, CA 
- core1.clt1.he.net - *Lumos / DC74 Data Center CLT-2 Charlotte * @ Charlotte, NC, US 
- core1.cys1.he.net - *ACT Cheyenne * @ Cheyenne, WY, US 
- core1.chi1.he.net - Equinix Chicago, AMS-IX Chicago *Equinix Chicago (CH1/CH2) * @ Chicago, IL, US 
- core1.cmh1.he.net - OhioIX *Cologix Columbus * @ Columbus, OH, US 
- core1.dal1.he.net - Equinix Dallas, CyrusOne, MegaIX Dallas *Equinix Dallas (DA1) * @ Dallas, TX, US 
- core1.den1.he.net - Any2 Denver, IX-Denver *CoreSite Denver * @ Denver, CO, US 
- core1.det1.he.net - DET-IX *123NET Detroit * @ Southfield, MI, US 
- core1.yeg1.he.net - YEGIX *Wolfpaw, Edmonton * @ Edmonton, AB, CA 
- core1.fmt1.he.net - *Hurricane Electric Fremont 1 * @ Fremont, CA, US 
- core1.fmt2.he.net - FCIX *Hurricane Electric Fremont 2 * @ Fremont, CA, US 
- core1.hnl1.he.net - DRF IX *DRFortress Honolulu * @ Honolulu, HI, US 
- core1.hou1.he.net - *Consolidated Houston * @ Houston, TX, US 
- core1.ind1.he.net - MidWest-IX Indy *Lifeline Henry Street Indianapolis * @ Indianapolis, IN, US 
- core1.mci1.he.net - *Level3, Kansas City * @ Kansas City, MO, US 
- core1.mci2.he.net - KCIX *Oak Tower Kansas City * @ Kansas City, MO, US 
- core1.mci3.he.net - *1102 Grand Kansas City * @ Kansas City, MO, US 
- core1.las1.he.net - *Fiberhub Las Vegas * @ Las Vegas, NV, US 
- core1.lax1.he.net - Equinix Los Angeles, LAIIX, MegaIX Los Angeles *Equinix Los Angeles (LA1) * @ Los Angeles, CA, US 
- core1.lax2.he.net - Any2 Los Angeles *CoreSite One Wilshire * @ Los Angeles, CA, US 
- core1.msn1.he.net - MadIX *5NINES Madison * @ Madison, WI, US 
- core1.mia1.he.net - FL-IX, NOTA *Equinix MI1 Miami * @ Miami, FL, US 
- core1.msp1.he.net - MICE *Cologix Minneapolis * @ Minneapolis, MN, US 
- core1.yqm1.he.net - *Fibre Centre Moncton * @ Moncton, NB, CA 
- core1.mgm1.he.net - MGMix Montgomery *RSA Dexter Montgomery * @ Montgomery, AL, US 
- core1.ymq1.he.net - QIX Montreal *Cologix Montreal / CANIX 3 * @ Montreal, QC, CA 
- core1.bna1.he.net - NashIX *365 Data Centers NA1, Nashville * @ Nashville, TN, US 
- core1.nyc4.he.net - Equinix New York *Equinix New York (NY9) * @ New York, NY, US 
- core1.nyc5.he.net - BigAPE, Telx-TIE New York *Digital Realty / Telx New York (NYC1), 60 Hudson * @ New York, NY, US 
- core1.nyc6.he.net - DE-CIX NY, NYIIX *Telehouse New York, Chelsea * @ New York, NY, US 
- core1.ewr1.he.net - *165 Halsey MMR - Tishman, Newark * @ Newark, NJ, US 
- core1.oma1.he.net - OmahaIX *Nebraska Colocation Centers Omaha * @ Omaha, NE, US 
- core1.pao1.he.net - Equinix Palo Alto, NASA-AIX *Equinix Palo Alto (SV8) * @ Palo Alto, CA, US 
- core1.phl1.he.net - *Equinix Philadelphia (PH1) * @ Philadelphia, PA, US 
- core1.phx1.he.net - Telx-TIE Phoenix *Digital Realty / Telx Phoenix (PHX1), 120 E Van Buren * @ Phoenix, AZ, US 
- core1.phx2.he.net - Phoenix IX *PhoenixNAP * @ Phoenix, AZ, US 
- core1.pdx1.he.net - NWAX *Pittock Building Portland * @ Portland, OR, US 
- core1.pwm1.he.net - NNENIX *MFC Portland Regen Site, Portland * @ Portland, ME, US 
- core1.rst1.he.net - *Neutral Path Rochester * @ Rochester, MN, US 
- core1.slc1.he.net - SLIX *Databank / C7 Salt Lake City * @ Salt Lake City, UT, US 
- core1.sfo1.he.net - SFMIX *Digital Realty / Telx (SFR1) San Francisco * @ San Francisco, CA, US 
- core1.sjc1.he.net - AMS-IX Bay Area, Any2 San Jose *CoreSite SV1 / Hurricane Electric San Jose 1 * @ San Jose, CA, US 
- core1.sjc2.he.net - Equinix San Jose *Equinix San Jose (SV1) * @ San Jose, CA, US 
- core1.yxe1.he.net - *University of Saskatchewan * @ Saskatoon, SK, CA 
- core1.sea1.he.net - Equinix Seattle, MegaIX Seattle, SIX *Equinix Seattle (SE2), Westin Building * @ Seattle, WA, US 
- core1.stl1.he.net - MidWest-IX STL *Netrality 210 N Tucker St. Louis * @ St. Louis, MO, US 
- core1.tpa1.he.net - TPAIX *365 Data Centers TA1, Tampa * @ Tampa, FL, US 
- core1.tor1.he.net - Equinix Toronto, MegaIX Toronto *Equinix Toronto (TR1) * @ Toronto, ON, CA 
- core1.yvr1.he.net - VANIX Vancouver *Cologix Vancouver * @ Vancouver, BC, CA 
- core1.ywg1.he.net - MBIX, WPGIX *Global Server Center, Winnipeg * @ Winnipeg, MB, CA 
- core1.syd1.he.net - *Equinix SY1, Sydney * @ Sydney, AU 
- core1.bog1.he.net - *Equinix BG1, Bogota * @ Bogota, CO 
- core1.sao1.he.net - PTT Sao Paulo *Equinix Sao Paulo (SP2) * @ São Paulo, BR 
- core1.jib1.he.net - DjIX *Djibouti Data Center, Djibouti * @ Djibouti City, DJ 
- core1.jnb1.he.net - NAPAfrica, JINX *Teraco JB1, Johannesburg * @ Johannesburg, GP, ZA 
- core1.nbo1.he.net - KIXP *EADC Nairobi * @ Nairobi, KE 
- core1.dxb1.he.net - UAE-IX *Equinix Dubai (DX1) * @ Dubai, AE 
- core1.hkg1.he.net - AMS-IX HK, Equinix Hong Kong, HKIX, IAIX, BBIX Hong Kong *MEGA-iAdvantage Hong Kong * @ Hong Kong, HK 
- core1.osa1.he.net - BBIX Osaka, JPNAP Osaka *Equinix Osaka (OS1) * @ Osaka, JP 
- core1.sel1.he.net - KINX *KINX Seoul * @ Seoul, KR 
- core1.sin1.he.net - Equinix Singapore, MegaIX Singapore *Equinix Singapore (SG1) * @ Singapore, SG 
- core1.tpe1.he.net - TPIX Taiwan *Chief LY Building, Taipei * @ Taipei, TW 
- core1.tyo1.he.net - BBIX Tokyo, Equinix Tokyo, JPNAP Tokyo, JPIX Tokyo *Equinix Tokyo (TY2) * @ Tokyo, JP 
