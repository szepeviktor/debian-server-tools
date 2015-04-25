## Honlap karbantartás a részleges és teljes leállások megelőzésére

- betörés (malware fertőzés) esetén takarítás
- * biztonsági mentés fájlokról, adatbázisról naponta (5 GB-ig)
- biztonsági mentés fájlokról, adatbázisról havonta (5 GB-ig)
- magas fokú honlap biztonság, fájl változás jelentés 30 percenként
- domain név lejárat figyelés, új regisztráció, módosítás
- DNS (domain név kiszolgáló) beállítás, óránkénti monitorozás
- főoldali tartalom óránkénti monitorozás és hiba észlelés
- honlap elérhetőség monitorozás 1 percenként
- * PHP és MySQL futás monitorozás óránként
- WMT (Google Webmestereszközök) teljes rendberakása hetente
- * nem létező tartalomra mutató linkek (404) javítása naponta (hibanapló szűréssel)

### Honlap gyorsítás SEO-hoz

- PageSpeed 80+ ponton tartása (ha van mobil nézete a honlapnak, akkor ott is)
- * tartalom kiszolgáló hálózat (CDN) használat [Amazon CloudFront](http://aws.amazon.com/cloudfront/pricing/) (20 GB havi forgalomig)
- * valós oldal betöltési idő alacsonyan tartása
- böngésző gyorsítótárazás beállítása
- SEO kimutatás a Google keresőben való helyezésről grafikonon és emailben naponta
- kritikus SEO hibákról összefoglaló jelentés
- * keresőben (Google találti oldal) való megjelenés ellenőrzése

### Kód karbantartás

- WordPress (honlap motor) frissítés
- WordPress bővítmények frissítése
- * HTML hibák javítása (amelyekhez nem kell újraírni a honlapot)
- * Google Analytics és más követő kódok, beágyazott mérőkódok beállítása és ellenőrzése
- * újonnan felvitt tartalom ellenőrzése hetente (tipográfia és HTML használat)
- * képek optimalizálása (méret csökkentés, szebb betöltődés)

A csillagozottak ( * ) csak saját szerveren (VPS) valósíthatók meg.
