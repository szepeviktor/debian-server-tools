### Search for errors in a log file

```bash
grep -Ei -B 1 -A 1 "crit|err[^u]|warn|fail[^2]|alert|unknown|unable|miss|except|disable|invalid|cannot|denied|broken|exceed|unsafe|unsolicited" \
    /var/log/dmesg
grep -Ei -B 1 -A 1 "crit|err[^u]|warn|fail[^2]|alert|unknown|unable|miss|except|disable|invalid|cannot|denied|broken|exceed|unsafe|unsolicited" \
    /var/log/syslog
```

See: ${D}/monitoring/syslog-errors.sh

### Logging in syslog-style

Syslog time format: `date "+%b %e %T"`

Log to syslog: `echo MESSAGE|logger --tag "${TAG}[${PID}]"`

Log to anywhere else: `echo MESSAGE|sed -e "s/^/${TAG}[${PID}]: /"|ts "%b %e %T"`

### Courier log analyizer

```bash
courier-analogue --smtpinet --smtpitime --smtpierr --smtpos --smtpod --smtpof \
    --imapnet --imaptime --imapbyuser --imapbylength --imapbyxfer \
    --noisy --title="TITLE" /var/log/mail.log
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
#apt-get install -y virt-what systemd dmidecode
virt-what
systemd-detect-virt -c; systemd-detect-virt -v
dmidecode -s system-product-name
```

### Hurrican electric routers

```bash
wget -qO- http://lg.he.net/|sed -n -e 's;.*title="\([^"]\+\)".*>\(.\+\)<span>\([^<]\+\)<.*;\1 *\2* @ \3;p'
```

1. 184.105.223.234
1. 184.105.223.237
1. 62.115.49.169
1. 62.115.49.170

- core1.ams1.he.net - AMS-IX, NL-IX *NIKHEF Amsterdam* @ Amsterdam, NL
- core1.bcn1.he.net - CATNIX *Itconic / Telvent Barcelona* @ Barcelona, ES
- core1.beg1.he.net - SOX Serbia *Telenor Belgrade* @ Belgrade, RS
- core1.ber1.he.net - BCIX, ECIX Berlin *IPB CarrierColo Berlin* @ Berlin, DE
- core1.buh1.he.net - INTERLAN, RONIX *NXDATA-1 Bucharest* @ Bucharest, RO
- core1.bud1.he.net - BIX Budapest *CE Colo Budapest (Victor Hugo 1)* @ Budapest, HU
- core1.cph1.he.net - COMIX, DIX *Interxion Copenhagen* @ Copenhagen, DK
- core1.dus1.he.net - ECIX Dusseldorf *Interxion Dusseldorf* @ Düsseldorf, DE
- core1.dub1.he.net - INEX *Equinix / Telecity Dublin* @ Dublin, IE
- core1.fra1.he.net - DE-CIX, ECIX Frankfurt, KleyRex *Interxion Frankfurt 1* @ Frankfurt, DE
- core1.ham1.he.net - BREM-IX, DE-CIX Hamburg, ECIX Hamburg *GlobalConnect Hamburg* @ Hamburg, DE
- core1.hel1.he.net - FICIX *Digita* @ Helsinki, FI
- core1.lis1.he.net - GigaPix *Itcontic Lisbon* @ Prior Velho, Lisbon, PT
- core1.lon1.he.net - LoNAP *Telehouse East Docklands* @ London, UK
- core1.lon2.he.net - LINX *Equinix / Telecity London HEX6/7* @ London, UK
- core1.mad1.he.net - ESPANIX *Interxion Madrid* @ Madrid, ES
- core1.mrs1.he.net - France-IX Marseille, DE-CIX Marseille *Interxion MRS1* @ Marseille, FR
- core1.muc1.he.net - DE-CIX Munich, ECIX Munich *Equinix Munich MU1* @ München, DE
- core1.mil1.he.net - MIX, TOP-IX *MIX Milan Via Caldera* @ Milan, IT
- core1.par1.he.net *Interxion Paris 2* @ Paris, FR
- core1.par2.he.net - Equinix Paris, France-IX, LU-CIX *Telehouse Voltaire Paris (TH2)* @ Paris, FR
- core1.prg1.he.net - NIX.CZ, Peering.CZ *CEColo/Sitel Prague* @ Prague, CZ
- core1.rix1.he.net - SMILE-LV *LVRTC TV Tower* @ Riga, LV
- core1.rom1.he.net - NaMeX *NaMeX Rome* @ Roma, IT
- core1.sof1.he.net - BIX.BG, B-IX, NetIX, OM-NIX *Telepoint Sofia* @ Sofia, BG
- core1.sto1.he.net - NetNod-A, NetNod-B, SOLIX, STHIX *Telecity Bromma* @ Stockholm, SE
- core1.tll1.he.net - RTIX, TLLIX *Elion Sõle* @ Tallinn, EE
- core1.vie1.he.net - VIX *Interxion Vienna* @ Vienna, AT
- core1.vno1.he.net *Data Logistics Center* @ Vilnius, LT
- core1.waw1.he.net - POZIX, PLIX, THINX *PLIX/LIM Warsaw* @ Warsaw, PL
- core1.zrh1.he.net - Equinix Zurich, SwissIX *Equinix Zürich (ZH1)* @ Zurich, CH
- core1.ash1.he.net - Equinix Ashburn *Equinix Ashburn (DC2)* @ Ashburn, VA, US
- core1.atl1.he.net - SNAP, Telx-TIE Atlanta *Telx Atlanta (ATL1), 56 Marietta* @ Atlanta, GA, US
- core1.bos1.he.net - Boston Internet Exchange, Mass IX *One Summer* @ Boston, MA, US
- core1.yyc1.he.net - YYCIX *Datahive Calgary* @ Calgary, AB, CA
- core1.clt1.he.net *DC74 Data Center CLT-2 Charlotte* @ Charlotte, NC, US
- core1.chi1.he.net - Equinix Chicago, ChIX *Equinix Chicago (CH1)* @ Chicago, IL, US
- core1.cmh1.he.net - OhioIX *Cologix COL2 / DataCenter.BZ Columbus* @ Columbus, OH, US
- core1.dal1.he.net - Equinix Dallas, CyrusOne *Equinix Dallas (DA1)* @ Dallas, TX, US
- core1.den1.he.net - Any2 Denver *CoreSite Denver* @ Denver, CO, US
- core1.yeg1.he.net - YEGIX *Wolfpaw Edmonton* @ Edmonton, AB, CA
- core1.fmt1.he.net *Hurricane Electric Fremont 1* @ Fremont, CA, US
- core1.fmt2.he.net *Hurricane Electric Fremont 2* @ Fremont, CA, US
- core1.hnl1.he.net - DRF IX *DRFortress* @ Honolulu, HI, US
- core1.mci1.he.net *Level3 Kansas City* @ Kansas City, MO, US
- core1.mci2.he.net - KCIX *Oak Tower Kansas City* @ Kansas City, MO, US
- core1.mci3.he.net *1102 Grand Kansas City* @ Kansas City, MO, US
- core1.las1.he.net *Fiberhub Las Vegas* @ Las Vegas, NV, US
- core1.lax1.he.net - Equinix Los Angeles, LAIIX *Equinix Los Angeles (LA1)* @ Los Angeles, CA, US
- core1.lax2.he.net - Any2 Los Angeles *CoreSite One Wilshire* @ Los Angeles, CA, US
- core1.msn1.he.net - MadIX *5NINES Madison* @ Madison, WI, US
- core1.mia1.he.net - FL-IX, NOTA *Verizon Terremark Miami* @ Miami, FL, US
- core1.msp1.he.net - MICE *Cologix Minnesota* @ Minneapolis, MN, US
- core1.ymq1.he.net - QIX Montreal *Cologix Montreal / CANIX 3* @ Montreal, QC, CA
- core1.nyc4.he.net - Equinix New York *Equinix New York (NY9)* @ New York, NY, US
- core1.nyc5.he.net - BigAPE, Telx-TIE New York *Telx New York (NYC1), 60 Hudson* @ New York, NY, US
- core1.nyc6.he.net - DE-CIX NY, NYIIX *Telehouse New York, Chelsea* @ New York, NY, US
- core1.oma1.he.net *Nebraska Colocation Centers Omaha* @ Omaha, NE, US
- core1.pao1.he.net - Equinix Palo Alto, NASA-AIX *Equinix Palo Alto (SV8)* @ Palo Alto, CA, US
- core1.phx1.he.net - Telx-TIE Phoenix *Telx Phoenix (PHX1), 120 E Van Buren* @ Phoenix, AZ, US
- core1.phx2.he.net - Phoenix IX *PhoenixNAP* @ Phoenix, AZ, US
- core1.pdx1.he.net - NWAX *Pittock Building Portland* @ Portland, OR, US
- core1.rst1.he.net *Neutral Path Rochester* @ Rochester, MN, US
- core1.slc1.he.net - SLIX *C7 Salt Lake City* @ Salt Lake City, UT, US
- core1.sfo1.he.net - SFMIX *Telx San Francisco* @ San Francisco, CA, US
- core1.sjc1.he.net - AMS-IX Bay Area, Any2 San Jose *CoreSite / Hurricane Electric San Jose 1* @ San Jose, CA, US
- core1.sjc2.he.net - Equinix San Jose, MegaIX Bay Area *Equinix San Jose (SV1)* @ San Jose, CA, US
- core1.yxe1.he.net *University of Saskatchewan* @ Saskatoon, SK, CA
- core1.sea1.he.net - Equinix Seattle, MegaIX Seattle, SIX *Equinix Seattle (SE2), Westin Building* @ Seattle, WA, US
- core1.stl1.he.net *DRT 210 N. Tucker St. Louis* @ St. Louis, MO, US
- core1.tor1.he.net - Equinix Toronto *Equinix Toronto (TR1)* @ Toronto, ON, CA
- core1.yvr1.he.net - PIX Vancouver *Cologix Vancouver* @ Vancouver, BC, CA
- core1.ywg1.he.net - MBIX, WPGIX *Global Server Centre Winnipeg* @ Winnipeg, MB, CA
- core1.hkg1.he.net - AMS-IX HK, Equinix Hong Kong, HKIX, IAIX, MegaIX Hong Kong *MEGA-iAdvantage Hong Kong* @ Hong Kong, HK
- core1.osa1.he.net - BBIX Osaka, JPNAP Osaka *Equinix Osaka (OS1)* @ Osaka, JP
- core1.sel1.he.net - KINX *KINX Seoul* @ Seoul, KR
- core1.sin1.he.net - Equinix Singapore, MegaIX Singapore *Equinix Singapore (SG1)* @ Singapore, SG
- core1.tyo1.he.net - BBIX Tokyo, Equinix Tokyo, JPNAP Tokyo, JPIX Tokyo *Equinix Tokyo (TY2)* @ Tokyo, JP
- core1.sao1.he.net - IX.BR *Equinix São Paulo (SP2)* @ São Paulo, BR
