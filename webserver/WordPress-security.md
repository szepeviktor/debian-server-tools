# Prevent WordPress attack vectors

### Compromise from hosting provider

- Choose an enterprise-level server provider (e.g. UpCloud)
- Secure control panel access: 2FA, login notification
- Secure API

### Compromise through server software

- Use modern server software (OS, web server, PHP version, cache, database)
- Hide server software version
- Don't install multiple websites on a server / separate by OS user
- Disable file upload on the server

### Server-side

- HTTPS websites receive less attacks, force HTTPS (HSTS)
- Block known hostile networks (myattackers-ipset)
- Preventively block vulnerability scanners (wpf2b)
- Restrict access to core, theme and plugin files and directories (wordpress.inc.conf)
- Source code integrity check (hourly)
- Alert on source code change (hourly)
- Have daily offsite backups
- Keep backups for several days (a week)

### Application

- Delete unused plugins and themes
- Auditing plugins and themes (source code) - prefer authors providing enterprise services
- Install an auditing plugin
- Disable file editing

### Authentication

- One administrator
- One user per natural person
- Remove role from unused accounts
- Disallow weak passwords
- Two-factor authentication
- Alert on foreign country logins (PHP geoip_country_code_by_name() or Apache mod_maxminddb)
- Analyse HTTP headers on login (wpf2b)
- Limit login attempts (wpf2b)
