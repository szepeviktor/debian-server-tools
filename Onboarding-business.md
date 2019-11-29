# Új ügyfelekkel való ismerkedés (HU)

Segítség a helyes hozzáálláshoz.

### Tervezés

- Készül üzleti terv? Van kitűzött cél?
- Készül kulcsszó kutatás, piacfelmérés?
- Készül műszaki dokumentáció vagy drótváz?
- UX elemzés, tervezés, tesztelés lesz?

### Résztvevők

- Hányadik projektjük ez?
- Lesz projektvezető?
- Hány műszaki szakember fog résztvenni? (UX designer, grafikus, fejlesztő, SEO, PPC, social)
- Hány üzleti résztvevő lesz?

### Eszközök

- Milyen eszközöket fogunk használni?
  https://szepeviktor.typeform.com/to/O8bLIX
- Milyen környezetek lesznek? (develop, staging, beta, demo)

### Kétféle hozzáállás

1. El kell tartsa a céget a webes alkalmazás?
2. Vagy a webes alkalmazás csak egy melléktevékenység?

Igények és eredmények szerint.

1. Vagy az üzleti résztvevők igényeinek kielégítése
2. Vagy szakértői tervezés a máshonnan már ismert hibák elkerülésével,
   és a technikai tartozás (technical debt) folyamatos visszafizetésével
   &ndash; _például az erőforrások 10%-a erejéig_

Mit jelent a _kész_?

1. Akkor van kész egy funkció, ha az elvárt értéket írja ki
2. Akkor van kész valami, ha a kódolási stílus megegyező, kommentezve van, a statikus analízis nem jelez,
   és esetleg valaki átnézte a kódot, és van hozzá teszt

https://twitter.com/chopeh/status/926074073767206912

### Hogyan működik a proaktivitás?

A már ismert hibákat, hiba forrásokat az alábbi 3 módon lehet kezelni.

1. Megelőző jellegű javítása → 100%-ig biztos
2. Bevállaljuk, hogy hiba következik be → bizonytalan
3. Valamilyen módon - pl. tévedésből - nem következik be a hiba → elenyésző a valószínűsége


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
