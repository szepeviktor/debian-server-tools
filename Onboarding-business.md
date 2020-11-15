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

- A felhasználóktól származik a működési költség?
- Fognak-e emberek dolgozni az éles környezeten?
- Kik dolgoznak az alkalmazás gyártásban a következő szerepkörökben
  - Emberek irányításában és szoftver gyártás terén jártas vezető
  - Szolgáltatói fiókokat kezelő, velük kapcsolatot tartó adminisztrátor
  - Szoftver tervező mérnök
  - UI designer
  - Backend fejlesztő
  - Frontend fejlesztő
  - Tartalom szerkesztő
- Szerver telepítés és üzemeltetés
- Alkalmazás tervezés
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
- Arculati kézikönyv (style guide, brand guidelines) szerinti munka
- Projekt menedzser
  - Hogyan osztjuk be :one: az új fejlesztéseket, :two: hiba javításokat és :three: a technikai tartozást
  - Kap-e egy fejlesztő egyszerre 1-nél több feladatot
- Onboarding folyamat, _Product Tour_ Intercom-mal
- Valós idejű _Alkalmazás Dashboard_, döntés támogatás

### Cégen belüli kommunikáció

Cél: 1 közös platformon kommunikálni.

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

- Bevétel követés
- Új regisztrációk, előfizetési csomag választás
- Konverziók
- Az alkalmazásban létrehozott entitások darabszáma

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

Két fő (back-end és front-end) fejlesztő **olcsóbb** és gyorsabb, mint egy fő.

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

- Kód kommentelés (docblock, üzleti logika és a commit üzenetek is)
- Hiba kezelés (hiba kontextus, könnyű felderíthetőség) :point_right: ettől tönkremennek a cégek
- Kódolás nélküli (zero coverage) tesztek futtatása
- Egység (unit) és funkcionális tesztek írása
- Keretrendszer és csomag frissítés
- `TODO` és `FIXME` kommentek keresése a forráskódban
- Refaktorálás
