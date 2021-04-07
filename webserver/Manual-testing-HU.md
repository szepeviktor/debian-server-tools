# KTK (HU)

Kézi Tesztelési Kézikönyv v1.0.0

_Melyik kódbázist tesztelem?_

`project-api`

_Melyik verziót tesztelem?_

Verzió: `2.6.0` vagy commit hash

_Milyen készülékeken, böngészőkkel tesztelek?_

- **iPhone 6** oprendszer: iOS 13.2.2, böngésző: Mobile Safari v12.34
- **PC** Windows 10 v1803, Edge 42.17134.1038.0
- **PC** Debian GNU/Linux 10.1, Firefox 70.0.1
- AMP verzió tesztelése

:bulb: Tesztelés közben tartsd nyitva a böngésző konzolt, mobilon a _debug_ konzolt.

### Teljes életciklus tesztelése

- Regisztráció
- Sikeres fizetés/regisztráció jóváhagyása
- Fő ág (_happy path_) [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
  szerinti tesztelése, minden entitás létrehozás (C), megtekintés (R), módosítás (U) és törlés (D)
- Rendellenes használat (pl. 404 oldal, sikertelen fizetés) tesztelése, segítő (nem zsákutca) üzenetek ellenőrzése
- A már ismert és javított hibák tesztelése
- Felhasználói fiók törlése

### Kompatibilitás tesztelése

- Megosztható-e (aminek megoszthatónak kell legyen) Twitter-en, Facebook-on
- [Rich Results/Rich Snippets](https://search.google.com/test/rich-results) "Structured Data" használatával
- Google Tag Manager mér-e
- Reklám blokkolóval (AdBlock) működik-e
- [még több](Production-website.md#compatiblitity)

### Egyebek

- Nem webes részek tesztelése, pl. Mailchimp email, mobil app, SMS küldés
- Tesztelő eszközök futtatása, pl. https://securityheaders.io/ , https://validator.w3.org/ , https://developers.google.com/speed/pagespeed/insights/
