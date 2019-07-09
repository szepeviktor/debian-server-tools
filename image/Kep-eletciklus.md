# Képek életciklusa egy webes alkalmazásban (HU)

- [Cloudinary](https://cloudinary.com/features/image_manipulation) komplett képkezelés
  [Laravel integrációval](https://github.com/jrm2k6/cloudder)
- [Sirv](https://sirv.com/)


### Feltöltés

- Sérült kép, hibás kép, ismeretlen formátum, nem kép kezelése, *megfelelő hibaüzenet*
- Milyen formátumokat támogatunk, *legyen kiírva*, a GD2 extension - amit használunk -
  [ezeket támogatja](http://php.net/manual/en/function.imagetypes.php) ("Return Values" konstansok)
- Maximálisan feltölthető képfájl méret: 50? MB, *legyen kiírva*
- Minimális képméret alatt *hibaüzenet*: 330×330
- Egyszerre lehessen több képet kiválasztani feltöltésre
- A feltöltést képenként menjen (AJAX-szal, [chunk-olva](https://github.com/pionl/laravel-chunk-upload))
  egyszerre egy, így virtuálisan korlátlan mennyiségű képet fel lehet tölteni,
  *legyen korlát*, ne lehessen 50? darabnál többet feltölteni, mert lefagy a böngésző
- Hány kép lehet összesen egy entitáshoz (több alkalommal) feltöltve?

##### Normalizálás

- Maximális képméretre kicsinyítés: 3500×3500 (12 MP - A/4-es oldal 300 DPI felbontással)
- Formátum konvertálás: JPEG, 100%-os minőség
- Optimalizálás, azaz képfájl méret csökkentés [jpeg-archiver](https://github.com/danielgtaylor/jpeg-archive)
- Eredeti elmentése -> ez egy másik szolgáltatás
- Eredeti fájlnév elmentése adatbázisba,
  [hash-elt név](https://support.cloudinary.com/hc/en-us/articles/202520632--Can-our-users-upload-private-images-which-are-not-accessible-through-a-public-URL-)
  használata
- [EXIF adatok](https://hu.wikipedia.org/wiki/Exif) (kamera neve, időbélyeg stb.) eltárolása adatbázisban
  és kitörlése a képfájlból


### Feldolgozás és tárolás

- Szélek levágása (crop)
- Automatikus egyszínű szegély levágása (autocrop)
- Forgatás (rotate)
- Vízjelezés (watermark)
- Automatikus forgatás EXIF (kamera) adatokból (autorotate)
- Különböző helyeken és készülékeken használt méretek legenerálása (mobil, asztali, kiskép)
- Példák kép manipulációkra https://sirv-cdn.sirv.com/website/vid/SirvImageAttributesVid.mp4
- [360 fokos termékkép](https://cloudinary.com/blog/add_the_360_product_viewer_to_your_commerce_site_with_cloudinary),
  [interaktív 360 fokos](https://sirv.com/features/360-product-viewer/)

##### Machine Learning

- Cimkézés [Google Cloud Vision API](https://cloud.google.com/vision/) használatával,
  tárgyak felismerése (banán, Eifel-torony), emberi arcok hangulatának felismerése (szomorú, boldog)
- Emberi arcot tartalmazó képen az arc meghagyása https://github.com/interconnectit/my-eyes-are-up-here


### Kiszolgálás (letöltés)

- Hash-elt képfájl név
- A hash ne legyen kitalálható, legyen a hash-elt adatok között a képhez *nem* kapcsolódó adat,
  pl. időbélyeg, véletlen szám
- Minden AWS S3 bucket-hez külön AWS felhasználó
- CDN használata (tartalom kiszolgáló hálózat)
- *Hotlinking* védelem, azaz mások ne tölthessék be a képeket a saját honlapjukba (teszt időszakkal)
- Helykitöltő (placeholder) generálás https://blurha.sh/
- Hiányzó kép kezelése (image.onerror)
- Kép gyorsítótárazásának szabályozása: 1 nap (Cache-Control)


### Egyebek

- Különböző méretek újragenerálása
- Kép eltávolítás
- Biztonsági mentés készítése másik szolgáltatóhoz (programhiba, emberi hiba)
  [Backblaze B2](https://www.backblaze.com/b2/docs/quick_command_line.html)
- Teljes S3 bucket méret naplózása, riasztás 10? GB fölött
