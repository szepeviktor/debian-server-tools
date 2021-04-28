# Blocking WordPress attack vectors

### Strategy

1. Reject traffic from known hostile networks
1. Ban IP addresses on the very first suspicious request preventing futher scanning
1. Serve requests as quickly as possible to prevent DoS attacks
1. Lowest access level possible for users
1. Monitor everything (source code, traffic, humans)

### Compromise from your computer and mobile

- Do not store usernames and passwords in browsers
- Use a password manager
- Second opinion anti-malware software (HitmanPro.Alert)
- [Protect devices](/Onboarding.md#cyber-security)

### Compromise from hosting provider

- Choose an enterprise ready server provider (e.g. [UpCloud](https://www.upcloud.com/register/?promo=U29Q8S))
- Secure control panel access: 2FA, login notification
- Secure API: IP whitelisting
- Subscribe to [status updates](https://status.upcloud.com/)

### Compromise through server software

- Use modern server software (OS, web server, PHP version, in-memory cache, database, remote access with SSH)
- Hide server software version
- Don't install multiple websites on a server / separate by OS user
- Subscribe to [OS security updates](https://www.debian.org/security/)

### Server-side

- HTTPS websites receive less attacks: force HTTPS ([HSTS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security))
- Block known hostile networks ([myattackers-ipset](/security/myattackers-ipsets))
- Preventively block vulnerability scanners ([WAF for WordPress](https://github.com/szepeviktor/waf4wordpress))
- Restrict access to core, theme and plugin files and directories ([wordpress.inc.conf](/webserver/apache-conf-available/wordpress.inc.conf))
- Disable file upload to the server
- Source code integrity check ([hourly](/monitoring/tripwire-fake.sh))
- Alert on source code change ([hourly](/monitoring/siteprotection.sh))
- Have daily offsite [backup](/backup)
- Keep backups for one week

### Application

- Delete unused plugins and themes and demo content
- Audit plugins and themes (source code) -
  prefer [authors with enterprise mindset](/webserver/WordPress.md#plugin-authors-with-enterprise-mindset)
- Install an [auditing plugin](https://wordpress.org/plugins/wp-user-activity/)
- Disable file editing
- Block on WordPress security events ([WAF for WordPress](https://github.com/szepeviktor/waf4wordpress))
- Add SRI (Subresource Integrity) attributes to elements with foreign CDN content
- Content Security Policy (CSP) HTTP header
- Choose wisely if you decide on a [page builder](https://www.wpbeaverbuilder.com/?fla=2082)

### Authentication

- One administrator per site
- One user account per natural person
- Remove roles from unused accounts
- Disallow weak passwords
- Two-factor authentication
- Alert on foreign country logins (PHP `geoip_country_code_by_name()` or Apache mod_maxminddb)
- Analyse HTTP headers on login ([WAF for WordPress](https://github.com/szepeviktor/waf4wordpress))
- Disallow too short usernames and passwords ([WAF for WordPress](https://github.com/szepeviktor/waf4wordpress))
- Limit login attempts ([WAF for WordPress](https://github.com/szepeviktor/waf4wordpress))

### Maintenance :wrench:

Have me on board: viktor@szepe.net

###### This page contains affiliate links
