[> :hungary:](#sz%C3%A9pe-viktor-dolgozna-egy-v%C3%A1llalatnak)

[Videó egy honlap műszaki hátteréről  
![Honlap műszaki háttere](/Honlap-műszaki-háttere.png)](https://www.youtube.com/watch?v=dGi6O9naiN8)

# Viktor Szépe from Hungary would work for a Company

My main activity is **proactive** maintenance of web-based services: an application, an API or a website.  
These experiences could mean valuable feedback for your development team.  
(*Traffic light example* :vertical_traffic_light: *a developer sees the green light, I see red and amber.*)  
My focus is on security&safety and performance.

I build and [monitor](/monitoring/README.md) Debian-based web-servers. Email delivery is on my radar.  
My howtos and scripts are open-source: https://github.com/szepeviktor/

I am also a **WordPress** expert. I know the core and develop plugins: https://profiles.wordpress.org/szepeviktor#content-plugins

Support videos are favourites of mine: https://www.youtube.com/user/szepeviktor (*there are English videos*)

I hope I'll fit into your picture: viktor@szepe.net


## CV in English

- website speed design and optimization (also on mobile)
- conditional resource loading (Javascript, CSS, images)
- resources optimization
- general usability audit (e.g. FOUC)
- visitor behavior measurement
- web application optimization
- I am a WordPress expert
- wp-cli contribution
- malware infection (hacked website) cleanup
- WordPress security https://github.com/szepeviktor/wordpress-fail2ban
- WordPress plugin audit https://profiles.wordpress.org/szepeviktor#content-plugins
- PHP code styling
- code debugging
- error reporting https://github.com/szepeviktor
- shared hosting check (29 factors)
- webserver install
- SSL certificate install
- CDN setup
- DNS setup
- VPS evaluation by various benchmarks
- email server setup
- server maintenance
- maintenance tool development https://github.com/szepeviktor/debian-server-tools/
- proactive server and website monitoring
- client support videos https://www.youtube.com/user/szepeviktor/videos
  an English video: https://www.youtube.com/watch?v=8o3g85SeDQ8
- make mistakes

### Webserver stack

Essentially keep every operation in memory!

- Modern CPU, high *memory* bandwidth as WordPress is mainly memory copying, sub-msec disk access time, try UpCloud!
- Thin virtualization layer, try UpCloud! Keep away from popular, non-enterprise providers
- Fast operating system: No systemd, Enough entropy, IRQ balance, Low memory usage
- Block hammering attackers: Fail2ban, permanently block shadow nets
- Anycast DNS
- Quick webserver: Apache Event MPM
- Parallel connection CDN with RAM-like speeds (Amazon CloudFront)
- High speed SSL: ECDSA certificate, Entropy source, TLS1.2, Ciphersuites for AES-NI, SSL session cache, OCSP stapling, HTTP/2
- Modern PHP with OPcache, connected through FastCGI
- Lean WordPress installation: minimal and audited plugins only
- Redis in-memory object cache
- TokuDB (fractal tree) MariaDB engine
- Static resource optimization
- Cut on JavaScripts
- Continuous monitoring: Pingdom, HetrixTools

# Szépe Viktor dolgozna egy Vállalatnak

Web alapú rendszerek **proaktív** üzemeltetésével foglalkozok.  
Olyan dolgokkal, amelyek nem látszanak a képernyőn,
amiről sokan azt hisszük, hogy rendben vannak, tehát a hibák váratlanul jönnek elő.

Olyan helyen veszi hasznomat, ahol nehezen tolerálható az üzemszünet és az üzemzavar.

A fejlesztésbe technológiai tanácsokkal és konkrét javaslatokkal segítek be a tapasztalataim alapján.  
A közlekedési jelzőlámpa példával élve :vertical_traffic_light: a fejlesztők a zöldet látják, én a sárgát és a pirosat.  
A figyelmem az üzembiztonságon, a sérülékenységen és a sebességen van.

Debian alapú [webszervereket építek](http://xn--felhtrhely-w4a65k.hu/) és [üzemeltetek](/monitoring/README.md).
Email kézbesítéssel is foglalkozok.  
A jegyzeteim és a programjaim mind nyílt forrásúak: https://github.com/szepeviktor/

Emellett WordPress - jobb szó híján - szakértő is vagyok.
Ismerem a magot (core) és bővítményeket fejlesztek: https://profiles.wordpress.org/szepeviktor#content-plugins

A support videók a kedvenceim: https://www.youtube.com/user/szepeviktor (angolul is vannak)

### Az alábbiakban veszi hasznomat

+ Webes szolgáltatás proaktív üzembentartása
+ Szerver és WordPress telepítés, monitorozás
+ Konstruktív hibajegy nyitás és megoldások ezekre:

1. WordPress üzembiztonság, monitorozás - legyen gazdája a honlapnak
2. WP betörés-biztonság https://github.com/szepeviktor/wordpress-fail2ban
3. WP sebesség - szerver oldali megoldások, plugin és téma audit és javítás
4. WP téma - akár utólagos - szerkeszthetősége, szerkesztők menedzselése, oktatása https://www.youtube.com/user/szepeviktor
5. WP téma készítése HTML-ből (vagy PSD-ből sitebuilder segítségével) Bootstrap módon
6. Komplex honlapoknál tanácsadás: adatstruktúrák WP-s ábrázolása biztonságosan és gyorsan (azaz cache-elhetően)

Remélem bele illek a képbe valahogyan: viktor@szepe.net


## WordPress telepítés, üzemeltetés

#### Sebesség

- Gyors szerver (vagy tárhely) választás mérések útján (oprendszer, SSD, PHP verió, adatbázis)
- PHP OPcache bekapcsolás
- Memória cache használat (Redis)
- HTTP/2
- Statikus fájlok cache-elése
- CDN, azaz tartalom kiszolgáló hálózat (Amazon CloudFront)

#### Biztonság

- Saját fejlesztésű WAF WordPress-hez (applikációs tűzfal)
- HTTPS (zöld lakat bal felül a böngészőben)
- Audit napló
- Felhasználó menedzsment (erős jelszó, KeePass ajánlás)
- Integritás ellenőrzés (fájl változás észlelés)
- Napi mentés

#### Üzembiztonság

- Honlap monitorozás (HTTP)
- Domain, DNS figyelés
- Webszerver hibanapló figyelés


## WordPress honlap/sablon készítés HTML kódból

#### Tartalom kezelés

- UX tervezés szerkesztőknek (egérrel építhető oldalak)
- Minden tartalmi elem könnyen szerkeszthető
- "Sablon beállítások" oldal készítés plugin nélkül
- Többnyelvűsítés (egynyelvű honlapon is)
- Egyeztetés a sitebuilderrel WP HTML struktúrákról (body_class, wp_nav_menu stb.)

#### Biztonság

- Saját fejlesztésű WAF WordPress-hez (applikációs tűzfal)
- Sérülékeny kód kerülése
- Spam védelem (kapcsolat űrlap, hozzászólás, regisztráció)
- Erős felhasználói jelszó megkövetelés

#### Sebesség

- HTTP kérések számának csökkentése
- Üzembiztos, biztonságos és gyors bővítmények (minél kevesebb)
- Cache használata (gyorsítótár)


## Magyarul az önéletrajz

- webhely sebesség tervezés és optimalizálás (mobilon is)
- feltételes erőforrás betöltés (Javascript, CSS, képek)
- erőforrások optimalizálása
- általános usability (használhatósági) audit (pl. [FOUC](https://en.wikipedia.org/wiki/Flash_of_unstyled_content))
- webhely látogatók viselkedésének mérése
- WordPress szakértő vagyok
- fertőzött (vírusos) honlap kitakarítás
- WordPress biztonság https://github.com/szepeviktor/wordpress-fail2ban
- wp-cli "contributor" (közreműködő) vagyok, a WordPress parancssori felületéhez írok részeket
- WordPress bővítmény audit https://profiles.wordpress.org/szepeviktor#content-plugins
- webes applikáció optimalizálás
- PHP "code styling" - a kód egyöntetűsége, és alapvető hibák kiküszöbölése
- hibakeresés kódban
- hiba jelentés https://github.com/szepeviktor
- webszerver telepítés
- SSL tanúsítvány telepítés
- CDN (tartalom kiszolgáló hálózat) beállítása
- DNS beállítás
- VPS értékelés teljesítmény adatok mérése alapján
- oszott tárhely ellenőrzése (29 faktor)
- levél szerver installálás
- szerver karbantartás
- karbantartáshoz használt eszközök fejlesztése https://github.com/szepeviktor/debian-server-tools/
- proaktív szerver és webhely monitorozás https://github.com/szepeviktor/debian-server-tools/blob/master/Maintenance.md
- ügyfél támogató videók https://www.youtube.com/user/szepeviktor/videos
- hibát vétek

## WordPress fejlesztő keresés

- http://wphu.org/wordpress-fejlesztes
- http://weblabor.hu/munka
- http://jobs.wordpress.net/post-a-job/
