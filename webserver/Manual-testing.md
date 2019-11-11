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

### Teljes életciklus tesztelése

- Regisztráció
- Sikeres fizetés/regisztráció jóváhagyása
- Használat [CRUD szerint](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete),
  minden entitás létrehozás (C), megtekintés (R), módosítás (U) és törlés (D)
- Rendellenes használat (pl. sikertelen fizetés) tesztelése, segítő (nem zsákutca) üzenetek ellenőrzése
- A már ismert és javított hibák tesztelése
- Felhasználói fiók törlése

### Kompatibilitás tesztelése

- Google Tag Manager mér-e
- Megosztható-e (aminek megoszthatónak kell legyen) Twitter-en és Facebook-on

### Egyebek

Az alkalmazás nem webes részeinek tesztelése, pl. Mailchimp email
