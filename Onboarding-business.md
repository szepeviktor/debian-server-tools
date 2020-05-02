# Új ügyfelekkel való ismerkedés (HU)

## Alkalmazás gyártás menete

- https://www.fps.hu/work
- https://web.archive.org/web/20181228074713/http://kozpontbanazember.hu/ (FrancisKodak)
- https://www.google.hu/search?q=user+interview+site%3Ahu

### Megismerés / Discover

Ismernünk kell az üzleti céljait, alapértékeit
és azonosítani felhasználóinak igényeit
olyan kutatási módszerek alapján,
mint a felhasználó interjúzás, terepkísérlet (field study) stb.

### Kiértékelés-Meghatározás / Define

Hogy a termék eleget tegyen a felhasználók igényeinek,
a funkcionalitás részletes leírást
és a tartalmi elemek meghatározást kell priorizálni.
Annak meghatározása, ahogyan a felhasználó interakcióba lép a funkciókkal,
az alkalmazás folyamatának (flow) és a tartalom struktúra megalkotása.

### Tervezés / Design

Designing interface elements to facilitate presenting the information
and the users’ movement through the information architecture by wireframes, prototypes.
Finally visualizing user interface by creative graphic design.
https://www.youtube.com/watch?v=mfieI1UBiaM

### Fejlesztés / Develop

Content and essential functions come ﬁrst,
then visual presentation and interactivity using the latest technology.
Testing products on a wide range of devices from mobile to desktop.


### Kérdések ismerkedéshez

- Lesz **sorozatosan** műszaki dolgok magyarázása nem műszaki emberek számára?
- Fogok kapni köznyelven folyószövegként írt emaileket és hibajegyeket?
- Milyen eszközöket fogunk használni?
  https://szepeviktor.typeform.com/to/O8bLIX
- Milyen (futtatási) környezetek lesznek?
  fejlesztési/tesztelési, staging, éles, béta, demó/sandbox

### Kétféle hozzáállás

1. Vagy az üzleti résztvevők igényeinek kielégítése
2. Vagy szakértői tervezés a máshonnan már ismert hibák elkerülésével,
   és a technikai tartozás (technical debt) folyamatos megfizetésével

Mit jelent a _kész_?

1. Akkor van kész egy funkció, ha az elvárt értéket írja ki
2. Akkor van kész valami, ha a kódolási stílus megegyező, kommentezve van, a statikus analízis nem jelez,
   és esetleg valaki átnézte a kódot, és van hozzá teszt

https://twitter.com/chopeh/status/926074073767206912

### Hogyan működik a proaktivitás?

A már ismert hibákat, hiba forrásokat az alábbi 3 módon lehet kezelni.

1. Megelőző jellegű javítása → 100%-ig biztos
2. Bevállaljuk, hogy hiba következik be → bizonytalan
3. Valamilyen módon - pl. szerencsével - nem következik be a hiba → elenyésző a valószínűsége


## Cég szervezés

Ami nincs leírva az [Onboarding-ban](/Onboarding.md).

- [Kiberbiztonság](/Onboarding.md#cyber-security) minden készüléken és másodlagos kártevővédelemi szoftver telepítés (HitmanPro.Alert)
- Jelszó menedzser bevezetése mindenkinél
- Céges telefonkönyv frissen tartás
- Céges kommunikáció meghatározása
- Arculati kézikönyv (style guide, brand guidelines) szerinti munka
- Projekt menedzser
  - Hogyan osztjuk be :one: az új fejlesztéseket, :two: hiba javításokat és :three: a technikai tartozást
  - Kap-e egy fejlesztő egyszerre 1-nél több feladatot
- Onboarding folyamat, _Product Tour_ Intercom-mal
- Valós idejű _Alkalmazás Dashboard_, döntés támogatás



### Céges kommunikáció

Cél: 1 közös platformon kommunikálni.

- hibajegy
- külsősökkel való kapcsolat a platformon belül vagy emailben
- jegyzetek, dokumentumok (pl. céges telefonkönyv) közös szerkesztése
- fájl megosztás
- naptár

Szolgáltató: [Clubhouse](https://clubhouse.io/)

* chat
* hanghívás, konferencia hívás
* videó hívás, képernyő megosztás

Szolgáltató: [Slack](https://slack.com/)

https://basecamp.com/

### Alkalmazás _Dashboard_

- Bevétel követés
- Új regisztrációk, előfizetési csomag választás
- Konverziók
- Az alkalmazásban létrehozott entitások darabszáma

* Commit-ok darabszáma
* Hibák darabszáma
* Hálózati forgalom
* Támadások száma

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
- Hiba kezelés
- Kódolás nélküli (zero coverage) tesztek futtatása
- Egység (unit) és funkcionális tesztek írása
- Keretrendszer és csomag frissítés
- `TODO` és `FIXME` kommentek keresése a forráskódban
- Refaktorálás
