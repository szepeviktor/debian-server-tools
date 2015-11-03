# Setting up a production website

## Setup

### SSL certificate

Security + trust.

1. Apache-SSL.md
1. https://www.ssllabs.com/ssltest/

### WordPress core, theme, uploads

`git clone --recursive ssh://user@server:port/path/to/git`

1. Turn off debugging
1. Set up database connection in `wp-config.php`
1. Edit `wp-cli.yml`
1. Define contants based of wp-config skeleton

### Search & replace various strings

Manual replace constants in `wp-config.php`.

`wp search-replace --precise --recurse-objects --all-tables-with-prefix ${OLD} ${NEW}`

1. `http://DOMAIN.TLD` or `https://` (no trailing slash)
1. `/home/PATH/TO/SITE` (no trailing slash)
1. `EMAIL@ADDRESS.ES` (all addresses)
1. `DOMAIN.TLD` (now without protocol)

### Install plugins

`wp --allow-root plugin install --activate classic-smilies`

`wp --allow-root plugin install --activate wordpress-seo w3-total-cache contact-form-7`

MU plugins: `wordpress-plugin-construction`

Security: `wordpress-fail2ban`

Disable comments? `mu-disable-comments`

Allow accents in URL-s? `mu-latin-accent-urls`

### Clean up database

See: `alter-table.sql`

`wp --allow-root plugin install --activate classic-smilies`

`wp --allow-root transient delete-all`

`wp --allow-root w3-total-cache flush`

`ls -l /home/${U}/website/html/static/cache/`

### Set up CDN

https://aws.amazon.com/console/

### Set up mail sending

Consider transactional email service: Amazon SES.

`wp --allow-root plugin install --activate wp-mailfrom-ii smtp-uri`

`wp --allow-root eval 'wp_mail("viktor@szepe.net","first outgoing",site_url());'`

- encode email addresses `antispambot( 'e@ma.il' )`
- shortest route of delivery
- email `From:` name and address
- subject
- identifing email notifications in office (filtering)
- SPF
- DKIM

Mandrill API: https://github.com/danielbachhuber/mandrill-wp-mail

### Set up cron jobs

`wp-cron-cli.sh`

### Redirect old URL-s

`wp --allow-root plugin install --activate safe-redirect-manager`

`https://www.google.com/search?q=site:${DOMAIN}`

### User management

- 1 administrator
- personal accounts for editors
- modify post and page authors
- enable/disable author sitemaps

## Check

### Code styling

- line ends
- indentation

### Theme and plugin check

1. theme meta, version in style.css
1. `query-monitor`
1. `theme-check`, http://themecheck.org/
1. `vip-scanner`
1. Frontend Debugger `?remove-scripts`
1. `p3-profiler`
1. https://validator.w3.org
1. https://www.webpagetest.org/

#### Typical design errors

- Dynamically generated resources (`style.css.php`)
- Extra server-side requests: HTTP, DNS
- `$_GET` and `$_POST` sanitization
- `<input type="file" />`
- Insufficient or excessive font character sets (`&subset=latin,latin-ext`)
- `@font-face` formats: eof, woff, ttf, svg
- Mobile views
- Permissions for editors
- Last one: basic site functionality, registration, contact forms

### 404 page

- informative
- cooperative
- attracktive

### Resource optimization

- image convert `convert $PNG --quality 100 $JPG`
- image rename `mv DSC-0005.JPG prefix-descriptive-name.jpg`
- image optimization `jpeg-recompress $JPG $OPTI_JPG`
- JS, CSS concatenation `cat small_1.css small_2.css > large.css`
- lazy or late loading ( slider, map, facebook, image gallery )
- light loading: `&controls=2`

### PHP errors

`tail -f /var/log/apache2/${SITE_USER}-error.log`

### SEO

- title (blue in SERP)
- permalink structure and slug optimization (green in SERP)
- meta desc (grey in SERP)
- h1, h2 / h3-h6
- img alt
- structured data https://schema.org/ http://microformats.org/
- [Google My Business](https://www.google.com/business/)

### Tracking

Set up and test

- Analytics, Remarketing
- Facebook pixel
- Piwik
- Clicktale

## Monitor

https://wiki.apache.org/httpd/ListOfErrors

1. filter error log `logsearch.sh -e|grep -Ev "AH00162|wpf2b_|bad_request_|no_wp_here_"`
1. watch error log `error-log-monitor` plugin
1. pingdom, `ping.php`
1. file change: `Tripwire`
1. connected services: API-s, CDN-s ...
1. recipient account: `cse`
1. recipient domain: expiry, DNS, blacklist

## Backup

1. DB
1. files
1. settings (connected services)
1. auth
