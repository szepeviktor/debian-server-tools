# Block WordPress attack vectors

### Compromise from hosting provider

- Choose an enterprise-level server provider (e.g. [UpCloud](https://www.upcloud.com/register/?promo=U29Q8S))
- Secure control panel access: 2FA, login notification
- Secure API

### Compromise through server software

- Use modern server software (OS, web server, PHP version, cache, database)
- Hide server software version
- Don't install multiple websites on a server / separate by OS user

### Server-side

- HTTPS websites receive less attacks: force HTTPS ([HSTS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security))
- Block known hostile networks ([myattackers-ipset](https://github.com/szepeviktor/debian-server-tools/tree/master/security/myattackers-ipsets))
- Preventively block vulnerability scanners ([WordPress Fail2ban](https://github.com/szepeviktor/wordpress-fail2ban))
- Restrict access to core, theme and plugin files and directories (wordpress.inc.conf)
- Disable file upload on the server
- Source code integrity check ([hourly](https://github.com/szepeviktor/debian-server-tools/blob/master/monitoring/tripwire-fake.sh))
- Alert on source code change ([hourly](https://github.com/szepeviktor/debian-server-tools/blob/master/monitoring/siteprotection.sh))
- Have daily offsite [backup](https://github.com/szepeviktor/debian-server-tools/tree/master/backup)
- Keep backups for several days (a week)

### Application

- Delete unused plugins and themes
- Audit plugins and themes (source code) - prefer authors providing enterprise services
- Install an [auditing plugin](https://wordpress.org/plugins/wp-user-activity/)
- Disable file editing
- Block on WordPress security events ([WordPress Fail2ban](https://github.com/szepeviktor/wordpress-fail2ban))

### Authentication

- One administrator
- One user per natural person
- Remove role from unused accounts
- Disallow weak passwords
- Two-factor authentication
- Alert on foreign country logins (PHP `geoip_country_code_by_name()` or Apache mod_maxminddb)
- Analyse HTTP headers on login ([WordPress Fail2ban](https://github.com/szepeviktor/wordpress-fail2ban))
- Limit login attempts ([WordPress Fail2ban](https://github.com/szepeviktor/wordpress-fail2ban))
