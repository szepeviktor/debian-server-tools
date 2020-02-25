[:hungary:](#hu)&nbsp;&nbsp;&nbsp;[:uk:](#en)


## <a name="en"></a>Maintenance of WordPress websites on a cloud server and technical support

My main activity is **proactive** maintenance of existing websites and
[web applications](/webserver/PHP-development.md).  
These experiences could mean valuable feedback for your developer/s.  
Traffic light example :vertical_traffic_light: a developer sees the green light,
[I see red](/webserver/WordPress-security.md) and amber.

### Proactive maintenance features

- Choosing service providers based on [measurements](https://github.com/szepeviktor/wordpress-speedtest)
- Modern OS and software on your server
- Server and website [monitoring](/monitoring/README.md) by functional tests and integrity checks
- Monitoring of 3rd-parties too
- Log analysis, alerts
- Software updates by reading changelogs
- Intelligent backup
- **Reporting issues** to editors and developers
- User management, user support over the phone, in email or chat
  and [how-to videos](https://www.youtube.com/user/szepeviktor) EN/HU
- Developing monitoring, **performance and security** [tools](https://github.com/szepeviktor/)
- Handmade [WordPress plugins](https://profiles.wordpress.org/szepeviktor#content-plugins)
- WordPress theme developer [tools](https://github.com/szepeviktor/wordpress-plugin-construction),
  plugin blacklist and suggestions
- Image optimization
- [Email delivery](/mail/README.md)

### Benefits

- **Stable operation**
- Fast page loads
- Website security
- Better UX for visitors and editors also
- Higher Google Search ranking
- Fewer **unexpected** situations

Contact me: viktor@szepe.net

### Webserver stack

Essentially keep every operation in memory!

- Modern CPU, high *memory* bandwidth as WordPress is mainly memory copying,
  sub-msec disk access time, use [UpCloud](https://www.upcloud.com/register/?promo=U29Q8S)
- Thin virtualization layer, use UpCloud, stay away from popular, non-enterprise providers
- Fast operating system: No systemd, Enough entropy, IRQ balance, Low memory usage
- Block hammering attackers: Fail2ban, permanently block hostile networks
- Anycast DNS
- Quick webserver: Apache with Event MPM
- Parallel connection CDN with RAM-like speeds (Amazon CloudFront)
- [High speed SSL](https://istlsfastyet.com/): ECDSA certificate, Entropy source,
  TLS1.2, Ciphersuites for AES-NI, SSL session cache, OCSP stapling, HTTP/2
- Modern PHP with OPcache, FastCGI connected through UDS
- Lean WordPress installation: minimal and audited plugins only
- Redis in-memory object cache
- TokuDB (fractal tree) MariaDB engine
- Static resource optimization
- Cut on JavaScripts
- Continuous monitoring (Monit, Pingdom, HetrixTools)

### Infrastructure layers

- Choose a datacenter (location, power, cooling, security)
- Choose carriers (network)
- Set up an AS (Autonomous system)
- Set up redundant networking
- Set up SAN (Storage area network)
- Set up servers (power supply, fans, CPU, memory, chipsets)
- Install virtualization software
- Install network services (DNS resolvers, NTP, OS mirror)
- Monitor all of above (e.g. disk health, voltages, fan speeds, temperatures)
- Keep away spammer and hacker neighbors

* OS (Operating system: time, IRQ, entropy)
* Firewall (known hostile networks, individual attackers)
* MTA (Mail transfer agent)
* System backup
* Server software (webserver, database, in-memory cache, language interpreter)
* Monitoring (filesystem, clock, networking, processes, files)

- Application (code, static files)
- Package managers
- CLI (command line) tools
- Third parties (DNS, CDN, SSL OCSP, external monitoring, trackers, video platform, map, ESP)


## <a name="hu"></a>WordPress üzemeltetés cloud szerveren és műszaki támogatás

[![Honlap műszaki háttere](/Application-infrastructure.png)  
Videó egy honlap műszaki hátteréről (HU)](https://www.youtube.com/watch?v=dGi6O9naiN8)

Létező honlapok **proaktív** üzemeltetésével foglalkozok.  
Olyan dolgokkal, amelyek nem látszanak a képernyőn,
amiről sokan azt hisszük, hogy rendben vannak, tehát a hibák **váratlanul** jönnek elő.

Olyan helyen veszi hasznomat, ahol nehezen tolerálható az üzemszünet és az üzemzavar.

A **fejlesztésbe** technológiai tanácsokkal és konkrét kivitelezéssel segítek be a tapasztalataim alapján.  
A közlekedési jelzőlámpa példával élve :vertical_traffic_light:
a fejlesztők a zöldet látják, én a sárgát és a pirosat.  
A figyelmem az üzembiztonságon, a [sérülékenységen](/webserver/WordPress-security.md) és a sebességen van.

### Hogyan előzöm meg a hibákat?

- Megfelelő szolgáltató választás [mérések alapján](https://github.com/szepeviktor/wordpress-speedtest)
- Modern operációs rendszer és szoftver installálás a szerverére
- Ellenőrzött környezet felállítása a honlaphoz
- Szerver, honlap és külső szolgáltatók [monitorozás](/monitoring/README.md) (EN)
  funkcionális tesztekkel és integritás ellenőrzéssel
- Reggelente/óránként hibanaplók elemzése
- Szoftver frissítés changelog-ok olvasása alapján
- Intelligens biztonsági mentés heti rotációval
- **Hibajegy nyitás** a szerkesztőknek és a fejlesztőknek
- Felhasználó menedzsment, és felhasználó támogatás telefonon, emailben, chat-en
  és [videókkal](https://www.youtube.com/user/szepeviktor) (EN/HU)
- Monitorozó programok, **teljesítmény növelő és biztonsági**
  [eszközök fejlesztése](https://github.com/szepeviktor/)
- Gondosan készített [WordPress bővítmények](https://profiles.wordpress.org/szepeviktor#content-plugins)
- [Fejlesztői eszközök](https://github.com/szepeviktor/wordpress-plugin-construction)
  gyártása WordPress sablon készítéshez, bővítmény fekete-lista és javasolt bővítmények
- Kép fájl optimalizálás
- [Email kézbesítés](/mail/README.md) (EN)

### Előnyök

- **Stabil üzem**
- Gyors oldal betöltés
- Honlap sérülékenységek kiküszöbölése
- Jobb felhasználói élmény (UX) a látogatóknak és a szerkesztőknek is
- Jobb helyezés a Google Keresőben
- Kevesebb **váratlan** incidens

Keressen meg: viktor@szepe.net


### más: Honlap tervezés

Ezeket a csapatokat tartom képesnek arra, hogy hatékony, konverziót hozó honlapot,
[webáruházat](https://www.ocado.com/) tervezzenek.

- https://www.voov.hu/
- https://hacky.hu/
- https://neeed.us/
- https://www.pwstudio.hu/ - :fire: CodeIgniter
- https://www.upsolution.hu/ - Laravel
- https://splendex.io/
- https://netpeople.hu/

* https://www.finetune.hu/
* https://www.rblmarketing.hu/
* http://maarsk.com/
* http://www.surmanngyula.hu/


### más: WordPress fejlesztő keresés

- https://iamgergo.com/about/
- https://webikon.sk/
- https://www.bluechip.at/de/ueber-uns/leitung-team/
- https://www.towa-digital.com/wordpress/

* https://kinsta.com/blog/hire-wordpress-developer/
* https://jobs.wordpress.net/post-a-job/
* wphu.org/wordpress-fejlesztes/
