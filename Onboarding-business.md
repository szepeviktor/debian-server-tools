# Új ügyfelekkel való ismerkedés (HU)

## Alkalmazás gyártás menete

1. Megismerés / Discover
1. Kiértékelés-Meghatározás / Define
1. Tervezés / Design
1. Fejlesztés / Develop

- https://www.fps.hu/work
- https://web.archive.org/web/20181228074713/http://kozpontbanazember.hu/ (FrancisKodak)
- https://www.google.hu/search?q=user+interview+site%3Ahu

### Milyen szolgáltatásra van szükség?

- Van kitűzött cél a napi session-ök darabszámára? (1000/nap)
- A felhasználóktól származó pénz fogja fedezni a működési költségeket?
- Hozzá fog nyúlni valaki az éles környezethez?
- Kik fedik le az alábbi szakterületeket?
  - Emberek irányítása és a szoftver gyártás közötti híd (vezető)
  - Szolgáltatói fiókok kezelése és a velük való kapcsolattartás (adminisztrálás)
  - Szoftver tervezés
  - UI/UX design
  - Back-end fejlesztés
  - Front-end fejlesztés
  - Automatikus és kézi tesztek
  - Tartalom szerkesztés
- Szerver telepítés és üzemeltetés
- Alkalmazás kitalálása (define)
- Alkalmazás tervezés (design)
- Alkalmazás fejlesztés (develop)
- Define + Design + Develop lehetőségek
  1. Nem lesz ilyen fázis vagy egy másikkal össze lesz keverve
  1. Olyanok fogják csinálni, akik nem a fázisnak szakértői
  1. Külön szakembereket bérelünk fel rá
  1. Alkalmazottat veszünk fel rá
- Alkalmazás üzemeltetés
- Fejlesztés követése és PR-ek küldése
- Krízis kezelés
- Nem szakember oktatása, _best practice_ megokolása
- Email-ek feldolgozása, megbeszéléseken való rendszeres részvétel


## Cég szervezés

Ami nincs leírva az [Onboarding-ban](/Onboarding.md).

- [Kiberbiztonság](/Onboarding.md#cyber-security) minden készüléken
  és másodlagos kártevővédelemi szoftver telepítés (HitmanPro.Alert)
- Jelszó menedzser bevezetése mindenkinél
- Céges telefonkönyv frissen tartása
- Cégen belüli kommunikáció meghatározása
- Projekt menedzser
  - Hogyan osztjuk be :one: az új fejlesztéseket, :two: hiba javításokat és :three: a technikai tartozást
  - Kap-e egy dolgozó egyszerre 1-nél több feladatot
- Arculati kézikönyv (style guide, brand guidelines) szerinti munka
- Onboarding folyamat, _Product Tour_ Intercom-mal
- Valós idejű _Alkalmazás Dashboard_, döntés támogatás

### Cégen belüli kommunikáció

Cél: 1 közös platformon kommunikálni, az emailes kommunikációt kiszorítani.

##### Aszinkron

- Hibajegy
- Külsősökkel való kapcsolat a platformon belül
  vagy [email automatizálással](https://help.clubhouse.io/hc/en-us/articles/206093065-Setting-Up-Zapier-Integrations)
- Jegyzetek és dokumentumok (pl. céges telefonkönyv) közös szerkesztése
- Fájl megosztás
- Naptár
- Hang üzenet [Yac](https://www.yac.com/)
- Belső tudástár https://tettra.com/ https://www.getguru.com/

Szolgáltató: [Clubhouse](https://clubhouse.io/)

##### Egyidejű

- Chat
- Hanghívás, konferencia hívás
- Videó hívás, képernyő megosztás

Szolgáltató: [Slack](https://slack.com/)

##### Egyéb szolgáltatók

1. https://basecamp.com/
1. https://www.notion.so/


### Alkalmazás _Dashboard_

Adatvezérelt üzleti döntésekhez.

1. Nem kívánt dolgok megsokasodása
1. Kívánt dolgok elmaradása

- Bevétel követés
- Új regisztrációk, előfizetési csomag választás
- Konverziók
- Az alkalmazásban létrehozott aktorok darabszáma

* Commit-ok darabszáma
* Kinyitott és lezárt hibajegyek darabszáma
* Hibanapló hossza
* Hálózati forgalom
* Támadások száma

Szolgáltató: https://amplitude.com/


### Szerkesztő képességei

1. Tipográfiai alapismeretek
1. WYSIWYG szerkesztő profi használata
1. Tartalom életciklusának megtervezése, kivitelezése
1. SEO alapismeretek
1. Az URL részeinek ismerete
1. Saját bejövő linkek készítőivel való kapcsolat (pl. Facebook menedzserrel)
1. Képek és média életciklusának ismerete
1. Képek előfeldolgozása
1. Beszédes fájlnevek adása


## Kódolási büdzsé

Egy fő back-end és egy fő front-end fejlesztő
**olcsóbb**, gyorsabb és jobb munkát végez, mint egy fő.

- Specifikáció
- Technológiák kiválasztása
- Kód tervezés (architektúra)
- Grafikai dizájn és UX
- [MVP](https://en.wikipedia.org/wiki/Minimum_viable_product)
- Funkciók befejezése (az MVP-n felül)
- Kézi tesztelés
- Hiba javítás


### Technikai tartozás (technical debt)

https://twitter.com/StepsizeHQ/status/1156582846057844736

- Dokumentumok frissítése
- Kód kommentelés (docblock, üzleti logika és a commit üzenetek is)
- Hiba kezelés (hiba kontextus, könnyű felderíthetőség) :point_right: ettől tönkremennek a cégek
- Kódolás nélküli (zero coverage) tesztek futtatása
- Egység (unit) és funkcionális tesztek írása
- Keretrendszer és csomag frissítés
- `TODO` és `FIXME` kommentek keresése a forráskódban
- Refaktorálás
