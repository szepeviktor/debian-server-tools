# Setting up a production WordPress website

Not only for WordPress sites!

1. [Installation](#installation)
1. [Migration](#migration)
1. [Upgrade](#upgrade)
1. [Check](#check)
1. [Monitor](#monitor)
1. [Backup](#backup)
1. [Uninstallation](#uninstallation)


## Installation


### DNS setup

- A, CNAME (for [CDN](http://www.cdnplanet.com/cdns/))
- MX
- TXT records for SPF, DKIM, DMARC
- PTR records
- Proper TTL values

### SSL certificate

- For safety (personal data)
- For security (less attacks)
- For trust (green lock in browsers)
- For [better SEO ranking since 2014](https://webmasters.googleblog.com/2014/08/https-as-ranking-signal.html)
- For speed (enables HTTP/2)
- For receiving referrer information (up to April 2012)
- Very cheap

Authorities: Let's Encrypt,
[RapidSSL](https://cheapsslsecurity.com/sslbrands/rapidssl.html) (by DigiCert),
DigiCert
and other [SSL certificate authorities](https://www.netcraft.com/internet-data-mining/ssl-survey/)

[OCSP performance](http://uptime.netcraft.com/perf/reports/performance/OCSP)

1. [Apache-SSL.md](./Apache-SSL.md)
1. https://www.ssllabs.com/ssltest/ :snail:
1. https://crt.sh/

### WordPress core and theme as Composer packages

1. Set up database connection in `wp-config.php`
1. Define constants, generate salts based on [wp-config.php skeleton](./wp-install/wp-config.php)
1. Edit `../wp-cli.yml`
1. **Use child theme** for purchased themes
1. Keep custom plugins and themes in git repositories

### Plugins

- Document plugin licenses, access to support :snail:
- See plugin list in [WordPress.md](./WordPress.md#plugins)
- See MU plugins at https://github.com/szepeviktor/wordpress-plugin-construction
- Allow accents in URL-s? `mu-latin-accent-urls`

### Root files

- `/robots.txt` :snail:
- `/favicon.ico` :snail:
- `/apple-touch-icon.png` :snail:
- `/browserconfig.xml`
- [other files in the document root](https://github.com/szepeviktor/RootFiles)

### Maintenance mode and placeholder page

- Static all-inline HTML page
- `ErrorDocument 503 nice-page.html` + `RewriteRule "^" - [R=503,L]` + Retry-After header

### CDN

- Use a CDN with multiple A records `host -t A cdn.example.com` :snail:
- [Revving filenames](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/)
- Combine and minify CSS and JavaScript files
- HTML caching or `no-cache`?
- Disallow HTML pages on CDN (robots-cdn.txt)
- https://aws.amazon.com/console/
- https://www.cloudflare.com/a/login see also [/webserver/CloudFlare.md](/webserver/CloudFlare.md)

### Mail sending

```bash
wp plugin install --activate wp-mailfrom-ii smtp-uri
wp eval 'wp_mail("admin@szepe.net","first outgoing",site_url());'
```

- Obfuscate email addresses `antispambot( 'e@ma.il' )`
- [JavaScript href fallback](https://gist.github.com/joshdick/961154): https://www.google.com/recaptcha/admin#mailhide
- Authenticated delivery for monitoring emails
- Shortest route of delivery
- Add server as `RELAYCLIENT` on the smarthost
- Email `From:` name and address
- Subject line
- Easy identification for email notifications (filtering to mail folders)
- SPF for `MAIL FROM:`, SPF for `HELO`, DKIM, DMARC

Use transactional email service through HTTP API
or with a queueing MTA. :snail:

- Mailgun API: https://wordpress.org/plugins/mailgun/
- Amazon SES: https://github.com/humanmade/aws-ses-wp-mail
- Mandrill API: https://github.com/danielbachhuber/mandrill-wp-mail
- SparkPost API: https://wordpress.org/plugins/sparkpost/

### Security

- WAF [`waf4wordpress`](https://github.com/szepeviktor/waf4wordpress) :snail:
- _For shared hosting: Sucuri Scanner plugin_
- _[Ninja Firewall Pro](https://nintechnet.com/ninjafirewall/pro-edition/)_
- _PHP extension: ionCube24 `ic24.enable = on` (PHP file modification time protection)_
- File change notification
- Subresource Integrity (SRI)
  `integrity="sha256-$(cat resource.js|openssl dgst -sha256 -binary|openssl enc -base64)" crossorigin="anonymous"`
- Google Search Console ("*This site may harm your computer*" notification on SERP)
- Sucuri SiteCheck (includes Google Safe Browsing)
- Virustotal (HTTP API)
- **Maximum security**: convert website into static HTML +
  [Cognito Forms](https://www.cognitoforms.com/)
  or [doorbell](https://doorbell.io/)
  or [formspree](https://formspree.io/)
  or [FormKeep](https://formkeep.com/)
  `simply-static`, `static-html-output-plugin`

### Cron jobs

- Remove left-over WP-Cron events `wp cron event list; wp cron schedule list`
- Use real cron jobs `wp-cron-cli.sh` :snail:

### WordPress Settings

- General Settings
- Writing Settings
- Reading Settings
- Media Settings (fewer generated image sizes) :snail:
- Permalink Settings
- WP Mail From :snail:

### User management

- 1 administrator :snail:
- Personal accounts for editors and authors :snail:
- Correct post and page authors
- Enable/disable author sitemaps

### RSS feed

@TODO

- Number of posts
- Full content
- Images
- Comment feeds

### Signature as HTML comment

```html
<!-- Infrastructure, source code management and consulting: Viktor Szépe <viktor@szepe.net> -->
```

### Webmaster tools

- Google Search Console :snail:
- Bing Webmaster
- Yandex Webmaster


## Migration


### Search & replace URL and installation path

Replace constants in `wp-config.php`

`wp search-replace --precise --recurse-objects --all-tables-with-prefix ${OLD} ${NEW}`

1. `http://DOMAIN.TLD/wp-includes` -> `https://NEW-DOMAIN.TLD/SITE/wp-includes` (no trailing slash)
1. `//DOMAIN.TLD/wp-includes` -> `//NEW-DOMAIN.TLD/SITE/wp-includes` (no trailing slash)
1. `http://DOMAIN.TLD/wp-content` -> `https://NEW-DOMAIN.TLD/static` (no trailing slash)
1. `//DOMAIN.TLD/wp-content` -> `//NEW-DOMAIN.TLD/static` (no trailing slash)
1. `http://DOMAIN.TLD` (no trailing slash)
1. `//DOMAIN.TLD` (no trailing slash)
1. `/home/PATH/TO/SITE` (no trailing slash)
1. `EMAIL@ADDRESS.ES` (all addresses)
1. `DOMAIN.TLD` (now without protocol)

Check `home` and `siteurl`

```bash
wp option get home
wp option get siteurl
```

### Uploads, media

```bash
wp media regenerate --skip-delete --only-missing
```

Remove missing (base) images.

### Clean up database

Check database collation and table storage engines.

See [alter-table.sql](/mysql/alter-table.sql)

Delete transients and object cache.

```bash
wp plugin install --activate wp-sweep
wp transient delete-all
wp db query "DELETE FROM $(wp eval 'global $table_prefix;echo $table_prefix;')options WHERE option_name LIKE '%_transient_%'"
wp cache flush
```

Flush page cache.

```bash
wp w3-total-cache flush
ls -l /home/USER/website/code/static/cache/
ls -l /home/USER/website/pagespeed/; touch /home/USER/website/pagespeed/cache.flush
```

Check spam and trash comments.

```bash
wp comment list --status=spam --format=count
wp comment list --status=trash --format=count
```

Optimize database tables.

```bash
wp db optimize
```

### Remove development and testing stuff

- Sample / [Demo content](https://thispersondoesnotexist.com/) :snail:
- Code editor configuration file `.editorconfig`
- Files: `find -iname "*example*" -or -iname "*sample*" -or -iname "*demo*"`
- PHP-FPM pool configuration: `env[WP_ENV] = production`

### VCS

Put custom theme and plugins under git version control. :snail:

Keep git directory above document root.

### Redirect old URL-s (SEO)

`wp plugin install --activate safe-redirect-manager`

`https://www.google.com/search?q=site:DOMAIN`

Also redirect popular images.

### Flush Google public DNS cache

http://google-public-dns.appspot.com/cache :snail:


## Upgrade


### Things to stop before upgrade

- External monitoring - wait for Pingdom - `maintenance5.sh`
- Requests from the Internet - Apache - `service apache stop`
- Cron jobs (maintenance mode) - `service cron stop`
- Monitoring - Monit - `monit quit`
- Incoming emails piped into programs - Courier - disable alias


## Check


[What people remember on your website](https://zurb.com/helio) :snail:

### Marketing

- [Home made product photos](/Kaktusz-photo-shoot.jpg)
- [One-person video team](https://wistia.com/blog/startup-ceo-makes-videos),
  [Intro video](http://technomatic.hu/),
  [Silent room](https://www.youtube.com/watch?v=GeB6QoKEyCk)
- [Google Street View virtual tour](https://www.brand360.hu/szolgaltatasok/google-street-view-belso-nezet-tura/)
- External URL-s should open in new window :snail:
- Use emojis (meta desciption, titles)
- Abandoned cart :snail:
- [Contact widget](https://pepper.swat.io/)
- Newsletter subscribe
- Offer free download
- Exit modal or Hijack box: *coupon, free download, blog notification, newsletter* etc.
- Background: http://www.aqua.hu/files/pix-background/nv-gf-gtx-heroesofthestormgeneric-skin2-hun.jpg
- Sharing: https://www.addthis.com/ https://www.po.st/ http://www.sharethis.com/ :snail:
- Content to share: https://paper.li/
- A/B testing: Google Optimize, Optimonk

### Code styling

- UTF-8 encoding (no BOM)
- Line ends
- Indentation
- Trailing spaces `sed -i -e 's|\s\+$||' file.ext`

### Theme and plugin check

1. Theme meta and version in `style.css`
1. `query-monitor` errors and warnings
1. `theme-check` and http://themecheck.org/
1. `vip-scanner`
1. Frontend Debugger with `?remove-scripts`
1. `p3-profiler`
1. https://validator.w3.org/ :snail:
1. https://validator.nu/

#### Typical theme and plugin errors

- [**Mobile views**](https://webmasters.googleblog.com/2018/03/rolling-out-mobile-first-indexing.html)
  (responsive design),
  [Mobile-friendliness](https://search.google.com/test/mobile-friendly),
  [Accelerated Mobile Pages](https://search.google.com/test/amp) (AMP)
- Zooming in desktop browsers
- Dynamic page parts (e.g. rotating quotes by PHP)
- Dynamically generated resources `style.css.php` (fix: `grep -E "(register|enqueue).*\.php"`)
- New WordPress entry point (fix: `grep -E "\b(require|include).*wp-"`)
- Missing theme meta tags in `style.css`
- Missing resource version in `grep -E "wp_(register|enqueue)_.*\("` calls
- Script/style printing (instead of using `wp_localize_script(); wp_add_inline_script(); wp_add_inline_style();`
- Always requiring admin code (fix: `whats-running`)
- Lack of `grep -E "\\\$_(GET|POST)"` sanitization
- Missing *nonce* on input
- PHP short opentags (fix: `grep -F "<?="`)
- PHP errors, deprecated WP code (fix: `define( 'WP_DEBUG', true );`)
- Lack of permissions for WP editors
- Non-200 HTTP responses
- Extra server-side requests: HTTP, DNS, file access
- Independent e-mail sending (fix: `grep -E "\b(wp_)?mail\("`)
- Proprietary install/update (fix: disable TGM-Plugin-Activation)
- Home call, external URL-s (fix: search for URL-s, use Snitch plugin and `tcpdump`)
- Form field for file upload `<input type="file" />`
- Insufficient or excessive font character sets (fix: `&subset=latin,latin-ext`)
- `@font-face` formats: eof, woff2, woff, ttf, svg; position: top of first CSS
- [BOM](https://en.wikipedia.org/wiki/Byte_order_mark) (fix: `sed -ne '1s/\xEF\xBB\xBF/BOM!!!/p'`)
- Characters before `<!DOCTYPE html>`
- JavaScript code parsable - by dummy crawlers - as HTML (`<a>` `<iframe>` `<script>`)
- Page loading overlay, display content by JavaScript causing
  [FOUC](https://en.wikipedia.org/wiki/Flash_of_unstyled_content)
- Unnecessary Firefox caret
- Confusion in colors: normal text color, link and call2action color, accent color
- Email header and content check https://www.mail-tester.com/

### Duplicate content

- www -> non-www redirection
- Custom subdomain with same content
- Development domains
- Early access domain by the hosting company: `cpanel.server.com/~user`, `somename.hosting.com/`
- Access by IP address: `http://1.2.3.4/`

### 404 page

- Post and image removal policy (for bots, for humans, redirect to another post)
- Informative
  - Reassuring the user we know about the problem :snail:
  - How to go on? :snail:
- Attractive [404 pages on AWWWARDS](http://www.awwwards.com/inspiration/search?text=404)
- Cooperative
  - Search form
  - Out of stock message
    `get_page_by_path( untrailingslashit( $_SERVER['REQUEST_URI'] ) . '__trashed', OBJECT, $post_type )`
  - Automatic suggestions (specific category archive)
  - Promotions
  - Google's fixurl.js
  - Support: Intercom Bot on repeated attempts or a simple (3rd-party) feedback form :snail:
- [Adaptive Content Type for 404-s](https://github.com/szepeviktor/wordpress-plugin-construction/blob/master/404-adaptive-wp.php)
- Redirect with delay `<meta http-equiv="refresh" content="8; URL=/">`
- Other error pages (500, 503)

### Resource optimization

- File names with [special UNICODE characters](https://www.compart.com/en/unicode/block/U+0300)
  `LC_ALL=C grep -P '[\x80-\xFF]'` :snail:
- Image format `convert PNG --quality 100 JPEG`
- Image name `mv DSC-0005.jpeg prefix-descriptive-name.jpg`
- Image optimization `jpeg-recompress JPEG OPTI_JPEG` :snail:
- [Self-host Google Fonts](https://google-webfonts-helper.herokuapp.com/)
- [CSS statistics](https://cssstats.com/)
- JavaScript, CSS concatenation, minification `cat small_1.css small_2.css >large.css`
- [instant.page](https://github.com/instantpage/instant.page)
- Conditional, lazy or late loading (slider, map, facebook content, [image gallery](https://www.freepik.com/))
- Use [async and defer](http://www.growingwiththeweb.com/2014/02/async-vs-defer-attributes.html) for JavaScripts
- Light loading, `&controls=2` for YouTube
- HTTP/2 server push
- [DNS Prefetch, Preconnect, Prefetch, Prerender](http://w3c.github.io/resource-hints/#resource-hints)
- YouTube custom video thumbnail (Full HD)

### HTTP

- HTTP methods `GET POST HEAD` and `OPTIONS PUT DELETE TRACE` etc.
- https://redbot.org/
- Loading in IFRAME (Google Translate, Facebook app)
- https://securityheaders.io/ and see [Twitter's list](https://github.com/twitter/secureheaders/blob/master/README.md)
- https://report-uri.io/home/tools CSP, HKPK, SRI etc.
- https://www.webpagetest.org/
- https://speedcurve.com/
- [Silktide](https://silktide.com/)
- Does the website have a public API? (WP REST API, WooCommerce API)
- Test (REST) API with
  [Postman](https://chrome.google.com/webstore/detail/postman/fhbjgbiflinjbdggehcddcbncdddomop)

### PHP errors

wp-config.php: `define( 'WP_DEBUG', true );`

```bash
tail -f /var/log/apache2/SITE_USER-error.log | sed -e 's|\\n|\n●|g'
```

### SEO

- `blog_public` and robots.txt :snail:
- XML sitemaps linked from robots.txt :snail:
- Excluded pages: `noindex, nofollow` :snail:
- Page title (blue in SERP) :snail:
- Permalink structure and slug optimization (green in [SERP](https://en.wikipedia.org/wiki/Search_engine_results_page)) :snail:
- Page meta description (grey in SERP) :snail:
- Keyword planning: [Google suggested searches](https://moz.com/blog/how-googles-search-suggest-instant-works-whiteboard-friday),
  [Google related searches](https://moz.com/blog/how-google-gives-us-insight-into-searcher-intent-through-the-results-whiteboard-friday),
  [Google Trends](https://trends.google.com/)
- Breadcrumbs
- Headings: H1, H2 / H3-H6
- Images: `alt`, `title`
- [Content keyword density](https://www.seoquake.com/)
- [noarchive?](https://support.google.com/webmasters/answer/79812)
- Multilingual site (`hreflang` attribute)
- Structured data https://schema.org/ http://microformats.org/
- [Google My Business](https://www.google.com/business/) :snail:
- [Google Location Changer](https://seranking.com/google-location-changer.html)
- [AdWords Ad Preview](https://adwords.google.com/anon/AdPreview)
- http://backlinko.com/google-ranking-factors
- AdWords campaign as a SEO factor
- [ContentKing](https://www.contentkingapp.com/) SEO monitoring
- [SEO for startups :play_or_pause_button:](https://www.youtube.com/watch?v=El3IZFGERbM)

Google's [Search Quality Evaluator Guidelines](https://static.googleusercontent.com/media/guidelines.raterhub.com/en//searchqualityevaluatorguidelines.pdf)

### Legal (EN)

- [On privacy](https://www.oath.com/en-gb/my-data/#startingwithdata)
- Privacy Policy :snail:
- [Cookie Consent Kit](http://ec.europa.eu/ipg/basics/legal/cookies/index_en.htm#section_4) + opt out,
  [cookie notice template](http://ec.europa.eu/ipg/docs/cookie-notice-template.zip),
  [Cookie Consent wizard by Insites](https://cookieconsent.insites.com/download/),
  [EDAA Glossary](http://www.youronlinechoices.com/hu/szomagyarazat)
- Terms & Conditions
- *Operated by*, *Hosted at*
- `/.well-known/dnt-policy.txt`
- See https://termsfeed.com/

### Jogi dolgok (HU)

- Adatkezelési tájékoztató
  [EU általános adatvédelmi rendelet](https://eur-lex.europa.eu/legal-content/HU/TXT/HTML/?uri=CELEX:32016R0679)
  (GDPR, 2018. május 25-től érvényes) :snail:
    - HTML és PDF formátumban (PDF title)
    - A tájékoztató címében a honlap domain-ja
    - Fogalom értelmezés
    - Adatkezelő adatai, elérhetősége
    - Adatvédelmi felelős adatai
    - Adatfeldolgozók listája és tevékenységük és az adatok: látogató mérés, közösségi doboz, tárhely szolgáltató
    - **Cookie-k kezelése**
    - Offline adatok: ügyfélkapcsolat (email, telefon), könyvelés, kamera rendszer, papíron tárolt adatok
    - Az érintettek jogai, adatvédelmi incidens
    - Jogorvoslat, bíróság
    - Bírósági jogérvényesítés
    - Kártérítés és sérelemdíj
    - Törvényekre &sect; való hivatkozás
    - Kelt és érvényesség kezdete
    - [Felkészülés az Adatvédelmi Rendelet alkalmazására 12 lépésben](https://www.naih.hu/felkeszueles-az-adatvedelmi-rendelet-alkalmazasara.html)
- Impresszum (csak űrlaphoz kell)
- [ÁSZF](https://net-jog.hu/kapcsolat/) (vásárláshoz)
- Ingyenes [NAIH nyilvántartásba vétel](https://www.naih.hu/bejelentkezes.html) (hírlevél küldéshez)

### Compatiblitity

- JavaScript disabled
- OpenGraph for [Facebook](https://developers.facebook.com/docs/reference/opengraph)
  ([Sharing Debugger](https://developers.facebook.com/tools/debug/))
  and [Twitter](https://dev.twitter.com/cards/markup)
  ([Card validator](https://cards-dev.twitter.com/validator)) :snail:
- **Google Translate** (`notranslate` meta),
  Facebook app (running in an IFRAME),
  Google Search "Cached" :snail:
- GoogleImageProxy (Gmail, Google Images)
- Ad blockers and filter lists: uBlock Origin, Adblock Plus, Disconnect (Firefox ETP), Ghostery
- Microsoft Office, Libre Office (copy-and-paste content or open URL in office application)
- Text selection: color+background-color, disable selection, display share options on select (see Feedly)
- Keyboard-only navigation (tabbing, [skip navigation](https://webaim.org/techniques/skipnav/)) :snail:
- Emojis and UNICODE (entering, storing, displaying)
- Toolbar color of Chrome for Android (`theme-color` meta) :snail:
- [Windows 8 and 10 tiles](http://www.buildmypinnedsite.com/)
- [\<head> cheatsheet](https://gethead.info/)
- Phone numbers (clickable, tracked)
- Skype IE Add-on `<meta name="SKYPE_TOOLBAR" content="SKYPE_TOOLBAR_PARSER_COMPATIBLE">`
- [Printer](http://www.printfriendly.com/), [Gutenberg framework](https://github.com/BafS/Gutenberg)
- [Accessibility](https://userway.org/),
  [attributes](https://www.w3.org/TR/wai-aria/states_and_properties) for screen readers,
  [guidelines](https://www.w3.org/TR/WCAG21/)
- Reader mode (from Firefox `chrome://global/skin/aboutReaderContent.css`)

### Integration (3rd party services)

Document in `hosting.yml` and check functionality.

- Certificate Authority (OCSP servers for obtaining SSL certificate revocation status)
- A/B testing
- [External search](https://sitesearch360.com/)
- External resources (fonts)
- Video ([Wistia](https://wistia.com/about-wistia))
- Maps ([HERE](https://wego.here.com/))
- Social media ([Twitter card](https://cards-dev.twitter.com/validator))
- Widgets ([TripAdvisor Widgets](https://www.tripadvisor.com/Widgets))
- Tracking codes (make *UA-number* `"UN" + "parse" + "able"` or `"UA-" + (17*28711).toString() + "-1"`)
- Advertisement
- [Live chat](https://www.drift.com/product-tour/)
- Newsletter subscription
- [Payment gateway](https://www.six-payment-services.com/en/home/contacts.html)
- CDN

### Tracking

Gain access, set up and test.

- [Heap Analytics](https://heap.io/)
- Google Analytics (revenue tracking), Google Tag Manager :snail:
- Facebook Pixel
- Segment
- Clicktale
- Smartlook
- Hotjar
- URL shortening: Link tracking, Download tracking

Verifying and debugging trackers.

- [Wappalyzer](https://chrome.google.com/webstore/detail/wappalyzer/gppongmhjkpfnbhagpmjfkannfbllamg)
- [Tag Assistant](https://chrome.google.com/webstore/detail/tag-assistant-by-google/kejbdjndbnbjgmefkgdddjlbokphdefk)
- [Google Analytics Debugger](https://chrome.google.com/webstore/detail/google-analytics-debugger/jnkmfdileelhofjcijamephohjechhna)
- [Facebook Pixel Helper](https://chrome.google.com/webstore/detail/facebook-pixel-helper/fdgfkebogiimcoedlicjlajpkdmockpc)
- [Google Ads phone call tracking](https://support.google.com/google-ads/answer/6095883?co=ADWORDS.IsAWNCustomer%3Dfalse)
  `sessionStorage.setItem('_goog_wcc_debug', 'y');`
- Hotjar: add `hjdebug:true` to `_hjSettings` object

### Last checks

- Basic site functionality :snail:
- Registration :snail:
- Purchase :snail:
- Contact forms :snail:


## Monitor


See [/monitoring/README.md](/monitoring/README.md)

Uptime ([pingdom.com](https://www.pingdom.com/),
[hetrixtools.com](https://hetrixtools.com/),
[selectel.com](https://selectel.com/services/additional/monitoring/)) :snail:

[List of all errors in Apache httpd](https://wiki.apache.org/httpd/ListOfErrors)

Track application and JavaScript errors with [Sentry](https://docs.sentry.io/server/installation/)

Set up status page with [Cachet](https://cachethq.io/)


## Backup


1. Database
1. Files
1. Settings (connected 3rd party services)
1. Authentication data
1. External resources (S3 bucket)
1. Issues (Trello, GitLab)
1. Code repositories (GitLab, GitHub)


## Uninstallation


- Archive for long term
- Monitoring
- Backups
- DNS records
- PHP-FPM pool
- DB, DB user
- Webserver vhost, add placeholder page
- Revoke SSL certificates
- Fail2ban `logpath`
- Webserver logs
- Files
- Linux user
- Email accounts
- External resources (3rd party services)
- [Google Search Console](https://www.google.com/webmasters/tools/url-removal)



### Maintenance :wrench:

Have me on board: viktor@szepe.net
