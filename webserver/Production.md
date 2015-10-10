# Setting up a production website

## Setup

### WordPress core, theme, uploads

`git clone --recursive ssh://user@server:port/path/to/git`

1. Turn off debugging
1. Set up database connection in `wp-config.php`
1. Define contants based of wp-config skeleton

### Search & replace various strings

Manual replace constants in `wp-config.php`.

`wp search-replace --precise --recurse-objects --all-tables-with-prefix ${OLD_URL} ${NEW_URL}`

1. http://DOMAIN.TLD or https (no trailing slash)
1. /home/PATH/TO/SITE (no trailing slash)
1. EMAIL@ADDRESS.ES (all addresses)
1. DOMAIN.TLD (now without http)

### Plugins

`wp --allow-root plugin install --activate wp-clean-up classic-smilies`

`wp --allow-root plugin install --activate safe-redirect-manager wordpress-seo w3-total-cache contact-form-7`

MU plugins: `wordpress-plugin-construction`

Security: `wordpress-fail2ban`

Disable comments? `mu-disable-comments`

### Set up mail sending

`wp --allow-root plugin install --activate wp-mailfrom-ii smtp-uri`

`wp --allow-root eval 'wp_mail("viktor@szepe.net","first outgoing",site_url());'`


### Clean up database

See: `alter-table.sql`

`wp --allow-root transient delete-all`

`wp --allow-root w3-total-cache flush`

### Set up cron jobs

`wp-cron-cli.sh`

## Check

### Cody styling

- line ends
- indentation

### Theme check

1. http://themecheck.org/
1. `wp --allow-root plugin install --activate theme-check`
1. PHP-generated resources (`style.css.php`)

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

`tail -f /var/log/aapche2/${SITE_USER}-error.log`

### Frontend analysis

1. https://validator.w3.org
1. https://www.webpagetest.org/

### SEO

- title, meta desc
- h1/h2/h3-h6
- img alt-s

### Tracking

Set up Analytics/Piwik/Clicktale/Facebook pixel/Remarketing.

## Monitor

1. filter error log (alerts)
1. pingdom, `ping.php`
1. file change: `Tripwire`
1. connected services
1. recipient account: `cse`
1. recipient domain: expiry, DNS, blacklist

## Backup

1. DB
1. files
1. settings (connected services)
1. auth
