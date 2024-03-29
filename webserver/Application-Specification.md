# Sikeres kommunikáció webes alkalmazás tervezésekor

Sok hiba visszavezethető hiányos vagy ellentmondásos specifikációra.

Ezek késlekedést, költség növekedést és feszült légkört eredményeznek,
amiből sokszor a silány munka a kiút.

Üzleti specifikációt - szerintem - az alábbi háromféleképp lehet készíteni.

1. Ahogyan az [egyetemeken tanítják](https://inf.mit.bme.hu/sites/default/files/materials/category/kateg%C3%B3ria/oktat%C3%A1s/doktorandusz-t%C3%A1rgyak/szoftver-verifik%C3%A1ci%C3%B3-%C3%A9s-valid%C3%A1ci%C3%B3/11/SZVV_EA02_kovetelmenyek.pdf)
2. Hétköznapi nyelven megkötések nélkül
3. Az eddigi tapasztalatok alapján az előző kettő egyes elemeit felhasználva

:bulb: Ez a jegyzet a harmadik fajtának megvalósításában próbál meg segíteni.

### Mikor hasznos az írott specifikáció

1. Amikor a munkafolyamatok része, hogy a dokumentációt aktuálizáljuk
2. Amikor a projektben résztvevők napi rutinjának része, hogy dokumentációt olvasnak

### A Vízió

Mi az, amit az alkalmazás sikeres működése elér, okoz?

### Elnevezések és jelentésük

Projekt (munka)nevének,
aktorok (humán és gépi szereplők)
és használati esetekben előforduló elnevezések rögzítése.

### Használati esetek

A használati esetek (use case) leírásánál érdemes mindig a _Ki mit csinál?_ kérdésre válaszolni,
és a CRUD négy részét végig gondolni. (létrehozás, listázás, módosítás, törlés)

### Műszaki dolgok

- Meglévő arculat követése vagy új arculat létrehozása (logó, színek, betűtípusok, elrendezés)
- Specializált szolgáltatók használata kontra saját megoldások fejlesztése (esetleg szoftvercsomagok használata)
- Staging környezet
- Folyamatos integráció (CI)
- Egység tesztek (unit tests)
- [Egy webes alkalmazás részei](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/PHP-development.md#parts-of-an-application)
