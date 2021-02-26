# Teljesítménycentrikus webhely tervezése (HU)

Meghatározni valók egy sikerközpontú, munkaeszköznek tekintett honlaphoz.

[Google UX iránymutatás](https://growrevenue.io/secret-google-ux-playbooks/)

### Stratégia

1. Interneten elérhető a célközönség?
1. A honlap tartalom mely részeire van kapacitásunk, hogy _életben tartsuk_, azaz módosítsuk különböző mérések
   (látogatások, kattintások, A/B teszt, telefonos kérdések, eladási eredmények) alapján?
1. Milyen tartalom legyen a honlapon?
   *Ez szokott lenni egy honlapon* (káros téveszmék által meghatározott tartalom)
   **vs.** mérések alapján priorizált tartalom
1. Személyes (narrátor) jelleg fotókkal, videóval, idézetekkel
   **vs.** a cég és a munkatársak egy-egy oldalra való korlátozása
1. Ki miért jön? Melyik oldalra érkezik? Kivel mit érdemes közölni vagy ajánlani neki?
1. Honnan jönnek a látogatók?
    - organikus (Google Kereső)
    - közösségi média, térkép (Facebook, Youtube, Google Térkép, Instagram)
    - hírlevél, **tranzakciós email** felületek
    - PPC (Google Ads, Facebook Business, Etarget, YouTube hirdetés, LinkedIn Advertising)
    - affiliate rendszer, szolgáltatás közvetítők, partner honlapok (árgép, wolt, hírportálok, influenszerek)
1. Mivel foglalkozunk? pozicionáló mondat/szlogen/mottó
1. Kampányok betervezése előre
1. Tartalom életciklus: időszakos oldalak, landing page-ek, 404 oldal UX, átirányítások, képek, külső linkek
1. "Elhagyott kosár", visszafordulók, bámészkodók kezelése
1. Visszatérő látogatók kezelése
1. Értékelések, hozzászólások, visszajelzés
1. [Ügyfelekkel való kapcsolattartás](/Intercom.md)

### Tartalom

Piramis elv (mindent egyszerre megmutatni hiba)  
főoldal → tematikus aloldal → cikk/lexikon

Sok információ: szétszórt figyelem **vs.** Kevés információ: fókusz

- Arculati kézikönyv: szín és forma harmónia, 1 kiemelő szín, [vibráló dizájn](https://hellobala.hu/)
- Navigációs elemek UX problémái: lokáció, méret, kinyílás (*mega menü*, egér-fölöttére nyíló)
  [UX designer](https://skinnydesigns.hu/)
- CTA (call-to-action) gombok
- Interaktív elemek: **videó**, Ken Burns effektes slider/galéria,
  hírlevél, letölthető anyag, beúszó feliratkoztató, exit modal,
  kupon/kedvezmény, friss hírek, megosztás, [további elemek angolul](/webserver/Production-website.md#marketing)
  _Az a jó videó, amire a nézők első reakciója, hogy újra meg akarom nézni._
- 3D virtuális túra
  - [Google Térkép Utcakép](https://www.google.com/intl/hu/streetview/business/) belső nézet túra
  - Beágyazható [3D Matterport virtuális túra](https://www.brand360.hu/) beltérről
  - Panorámakép
  - [Facebook 360 fotók](https://facebook360.fb.com/360-photos/)
  - [Facebook 3D fotó](https://hu-hu.facebook.com/help/414295416095269)
- [Szövegbe ágyazott űrlap](https://www.towa-digital.com/wordpress/) ("coffee" gomb)
- [Social](https://provesrc.com/) [proof](https://www.nudgify.com/)
- Zsákutca hiba (Alul hova tovább?)
- Fölös háttér, belépési oldal,
  [köszönjük oldal](http://fast.wistia.net/embed/iframe/tra6gsm6rl), értesítő levelek kihasználása

### Technológia

1. Tervezés, prototyping, [vakszöveg](http://www.lorumipse.hu/), [wireframe](https://balsamiq.com/wireframes/)
    - https://whimsical.com/
    - https://www.figma.com/
    - https://www.invisionapp.com/
    - https://www.protopie.io/
    - https://www.framer.com/
1. Nézetek [mobilon](https://webmasters.googleblog.com/2018/03/rolling-out-mobile-first-indexing.html)
   és [AMP változat](https://support.google.com/google-ads/answer/7336292?hl=hu)
   és különböző készülékeken, böngészőkben
1. Látogatási folyamat (user flow) szimuláció, validálás, [tesztelés](https://helio.app/)
1. Tipográfia/szövegszerkesztővel bevihető elemek megtervezése:
   alcím, felsorolás, idézet, kép+felirat, galéria, videó, árlista, személyes infó (author bio)
1. Nyelvek
1. Megoszthatóság
1. [Mérés](https://github.com/googleanalytics/autotrack):
   bevétel, látogatás, oldalon belüli esemény (kattintás, menü kinyitás), konverzió, egér követés, hőtérképek

- [Google Cégem](https://support.google.com/business/answer/7091)
- [Google Tudáspanel](https://support.google.com/business/answer/6331288)
- [Google Térkép](https://support.google.com/business/answer/6056435)
