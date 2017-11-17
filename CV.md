[:hungary:](#sz%C3%A9pe-viktor-honlapokat-%C3%BCzemeltet)&nbsp;&nbsp;&nbsp;[:uk:](#viktor-sz%C3%A9pe-from-hungary-does-website-maintenance)

[![Honlap műszaki háttere](/Honlap-műszaki-háttere.png)  
Videó egy honlap műszaki hátteréről (HU)](https://www.youtube.com/watch?v=dGi6O9naiN8)

# Viktor Szépe from Hungary does website maintenance

My main activity is **proactive** maintenance of existing websites and web applications.  
These experiences could mean valuable feedback for your developer/s.  
Traffic light example :vertical_traffic_light: a developer sees the green light, I see red and amber.

### What does proactive maintenance mean?

- Choosing proper service providers based on [measurements](https://github.com/szepeviktor/wordpress-speedtest)
- Installing modern OS and software on your server
- Server and website [monitoring](/monitoring/README.md) by functional tests and integrity checks
- Monitoring of 3rd-parties too
- Log analysis, alerts
- Software updates by reading changelogs
- Intelligent backup
- **Reporting issues** to editors and developers
- User management, user support over the phone, in email or chat and [how-to videos](https://www.youtube.com/user/szepeviktor) EN/HU
- Developing monitoring, **performance and security** [tools](https://github.com/szepeviktor/)
- Handmade [WordPress plugins](https://profiles.wordpress.org/szepeviktor#content-plugins)
- WordPress theme developer [tools](https://github.com/szepeviktor/wordpress-plugin-construction), plugin blacklist and suggestions
- Image optimization
- [Email delivery](https://github.com/szepeviktor/debian-server-tools/blob/master/mail/README.md)

### Benefits

- **Stable operation**
- Fast page loads
- Website security
- Better UX for visitors and editors also
- Higher Google Search ranking
- Fewer **unexpected** situations

I hope I'll fit into your picture: viktor@szepe.net


### Webserver stack

Essentially keep every operation in memory!

- Modern CPU, high *memory* bandwidth as WordPress is mainly memory copying, sub-msec disk access time, try [UpCloud](https://www.upcloud.com/register/?promo=U29Q8S)!
- Thin virtualization layer, try UpCloud! Keep away from popular, non-enterprise providers
- Fast operating system: No systemd, Enough entropy, IRQ balance, Low memory usage
- Block hammering attackers: Fail2ban, permanently block shadow nets
- Anycast DNS
- Quick webserver: Apache with Event MPM
- Parallel connection CDN with RAM-like speeds (Amazon CloudFront)
- [High speed SSL](https://istlsfastyet.com/): ECDSA certificate, Entropy source, TLS1.2, Ciphersuites for AES-NI, SSL session cache, OCSP stapling, HTTP/2
- Modern PHP with OPcache, FastCGI connected through UDS
- Lean WordPress installation: minimal and audited plugins only
- Redis in-memory object cache
- TokuDB (fractal tree) MariaDB engine
- Static resource optimization
- Cut on JavaScripts
- Continuous monitoring (monit, Pingdom, HetrixTools)

# Szépe Viktor honlapokat üzemeltet

Létező honlapok és webes rendszerek **proaktív** üzemeltetésével foglalkozok.  
Olyan dolgokkal, amelyek nem látszanak a képernyőn,
amiről sokan azt hisszük, hogy rendben vannak, tehát a hibák **váratlanul** jönnek elő.

Olyan helyen veszi hasznomat, ahol nehezen tolerálható az üzemszünet és az üzemzavar.

A **fejlesztésbe** technológiai tanácsokkal és konkrét kivitelezéssel segítek be a tapasztalataim alapján.  
A közlekedési jelzőlámpa példával élve :vertical_traffic_light: a fejlesztők a zöldet látják, én a sárgát és a pirosat.  
A figyelmem az üzembiztonságon, a sérülékenységen és a sebességen van.

### Mit jelent a proaktív üzemeltetés?

- Megfelelő szolgáltató választás [mérések alapján](https://github.com/szepeviktor/wordpress-speedtest)
- Modern operációs rendszer és szoftver installálás a szerverére
- Szerver és honlap [monitorozás](/monitoring/README.md) funkcionális tesztekkel és integritás ellenőrzéssel
- Harmadik feleket is monitorozok
- Napló kivonatok elemzése, riasztások
- Szoftver frissítés changelog-ok olvasása alapján
- Intelligens biztonsági mentés
- **Hibajegy nyitás** a szerkesztőknek és a fejlesztőknek
- Felhasználó menedzsment, és felhasználó támogatás telefonon, emailben, chat-en és [videókkal](https://www.youtube.com/user/szepeviktor) (EN/HU)
- Monitorozó programok, **teljesítmény növelő és biztonsági** [eszközök fejlesztése](https://github.com/szepeviktor/)
- Gondosan készített [WordPress bővítmények](https://profiles.wordpress.org/szepeviktor#content-plugins)
- [Fejlesztői eszközök](https://github.com/szepeviktor/wordpress-plugin-construction) gyártása WordPress sablon készítéshez, bővítmény fekete-lista és javasolt bővítmények
- Kép fájl optimalizálás
- [Email kézbesítés](https://github.com/szepeviktor/debian-server-tools/blob/master/mail/README.md) (EN)

### Előnyök

- **Stabil üzem**
- Gyors oldal betöltés
- Honlap sérülékenységek kiküszöbölése
- Jobb felhasználó élmény (UX) a látogatóknak és a szerkesztőknek is
- Jobb helyezés a Google Keresőben
- Kevesebb **váratlan** incidens

Remélem bele illek a képbe valahogyan: viktor@szepe.net

## WordPress fejlesztő keresés

- http://wphu.org/wordpress-fejlesztes
- http://weblabor.hu/munka
- http://jobs.wordpress.net/post-a-job/
- https://kinsta.com/blog/hire-wordpress-developer/
