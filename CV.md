[:hungary:](#hu)&nbsp;&nbsp;&nbsp;[:uk:](#en)

# <a name="en"></a>Preventing machine and human errors while running your web application

DevOps can be seen as the foundation of my work,
which focuses on **proactive** maintenance of
[web-based systems](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/PHP-development.md).
This&nbsp;includes comprehensive understanding of the application,
full source code life cycle management, continuous integration (CI) and automated deployment (CD).

As a team member my exclusive focus is on **non-userfacing** parts
(sustainability, stability, vulnerability, performance) of the application.

### Proactive maintenance features

- You benefit from all incidents at all my clients (ever)
- I maintain a blacklist and a list of recommendations
  of technologies, software and business procedures
- You receive documentation on project procedures
- Many types of alerts and continuous log analysis

### How to build infrastructure?

We have to start planning (and error prevention)
from the bulldozer leveling the ground for the datacenter
and build infrastructure **and** the application from there up to browser rendering.

- choose **specialized** domain registrar, dns, ssl, cdn, email, backup providers
- choose an honest, proactive and technically advanced cloud provider:
  virtualization, network, storage, processor, memory
- modern and small operating system
- modern server software: webserver, fast SSL, database, in-memory cache, PHP environment
- network and application security
- deep monitoring of **everything** we have and depend on

Contact me: viktor@szepe.net



[![Honlap műszaki háttere](/Application-infrastructure.png)  
Videó egy honlap műszaki hátteréről (HU)](https://www.youtube.com/watch?v=dGi6O9naiN8)

# <a name="hu"></a>Infrastruktúra, forráskód kezelés és technológiai tanácsadás webes alkalmazásokhoz

A DevOps kifejezés jó kiindulási alap lehet megérteni a munkámat.  
[Webes rendszerek](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/PHP-development.md)
**proaktív** üzemeltetésével foglalkozok, ami magában foglalja az alkalmazás átfogó megértését,
a folyamatos integrációs teszteket (CI)
és automatizált telepítést (deploy, CD).
A&nbsp;technológiai ismereteim kiegészítik a fejlesztők ismereteit.

A figyelmem az alkalmazás nem felhasználó felőli részén (üzembiztonság, sérülékenység, sebesség)
van, ebből az következik, hogy szükség van más csapattagokra.

### Proaktív üzemeltetés előnyei

- Az összes ügyfelem (valaha történt) összes hibájának ellenszerét megkapja
- Vezetek tiltólistát és ajánlásokat
  technológiákról, szoftverekről és üzleti eljárásokról
- Dokumentáció készül a projektben folyó eljárásokról
- Sokféle riasztás és folyamatos napló elemzés

### Milyen területeken előzöm meg a hibákat?

- Infrastruktúra szolgáltatók
- Szerver programok
- Az alkalmazás futtató környezete
- Tervezés: kiválasztott szoftveres technológiák
- Kivitelezés: programozók, szerkesztők, marketingesek stb. munkája
- Futtatás: a frontend a böngészőben
- Felhasználók tevékenységei
- Hálózati és alkalmazás biztonság
- Harmadik felek (külső szolgáltatók) pl. A/B teszt, CDN, térkép, videó
- Email kézbesítés

### Milyen módon előzöm meg a hibákat?

- Szolgáltató választás [mérések alapján](https://github.com/szepeviktor/wordpress-speedtest)
- Modern operációs rendszer és szerver szoftver telepítése
- Ellenőrzött környezet felállítása az alkalmazáshoz
- Mindennek az átfogó [monitorozása](/monitoring/README.md) (EN) amink csak van, vagy függünk tőle
- Naplók folyamatos elemzése
- Intelligens és titkosított biztonsági mentés nagy adatsérülés-tűrésű szolgáltatóhoz

* [Folyamatos integráció](/webserver/Continuous-integration-Continuous-delivery.md) (CI) megtervezés és kivitelezés
* Alkalmazás telepítés (CD) automatizálás és ellenőrzés
* **Hibajegy nyitás** a fejlesztők felé
* Monitorozó programok, **teljesítmény növelő és biztonsági** [eszközök fejlesztése](https://github.com/szepeviktor/)
* [Email kézbesítés](https://github.com/szepeviktor/debian-server-tools/blob/master/mail/README.md) (EN)

Keressen meg: viktor@szepe.net

### Infrastruktúra szolgáltatók

1. Domain regisztrátor
1. DNS szolgáltató
1. Szerver szolgáltató
1. SSL tanúsítvány szolgáltató (HTTPS-hez)
1. CDN szolgáltató (statikus fájlokhoz)
1. Tranzakciós email kiküldő
1. Biztonsági mentés szolgáltató
