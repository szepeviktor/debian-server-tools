# Analytics URL builder (HU)

Kötelező mezők:

`https://utm.url-builder.tld/cél-honlap/forrás/médium/kampány`

Lehetséges bővítmények:

`https://utm.url-builder.tld/célhonlap/forrás/médium/kampány/tartalom/keresőszó`
`https://utm.url-builder.tld/célhonlap/forrás/médium/kampány//keresőszó`

Példa:

`https://utm.url-builder.tld/start-reg/partner-hirlevel/email/ajándék-SBE/kep`

Lehet a mezőkben ékezetes betű és szóköz is.

Mi micsoda?

- http://www.annielytics.com/guides/definitive-guide-campaign-tagging-google-analytics/
- http://blog.davingranroth.com/2011/11/how-i-use-utm_source-utm_medium-utm_campaign-from-google-analytics/

A nagyobb kategóriától a kisebb felé:

- `utm_source` Ez a mező azonosítja, hogy milyen rendszerből jön a kattintás, pl: partner-hirlevel, sztervezo
- `utm_medium` Milyen médiumon használjuk a festett linket, pl: email, cpc, honlap (site), közösségi oldalak (social)
- `utm_campaign` A kampány neve. Egy adott utm_source-on belül több kampány is lehet.
- `utm_content` Milyen tartalomat követünk ezzel a festett linkkel, pl: gomb, kép, link
Ezt A/B teszteknél az A és a B változat megkülönböztetésére kell használni.
- `utm_term` Fizetett kereséseknél (Google Adwords) ebben a mezőbe kerül a keresőszó, ha kézzel tag-eljük a kampányokat.

Hibánál az `error` nevű site-ra irányít át az alábbi festett linkkel, és naplózza a hibás linket:
`utm/honlap/festett-link-hiba`

#### Szükséges Apache (.htaccess) beállítás:

```htaccess
# UTM
RewriteEngine On
RewriteBase /
RewriteCond %{REQUEST_FILENAME} !-f
#RewriteRule "^" "/analytics-url-builder.php" [L]
RewriteRule "^" "/analytics-url-builder.php" [END]
```

### Robotoknak robots.txt:

```
User-agent: *
Disallow: /
```

### Favicon

Forrás: http://fortawesome.github.io/Font-Awesome/icon/share/

```bash
base64 -d < favicon.xz.b64 | xzcat > favicon.ico
```
