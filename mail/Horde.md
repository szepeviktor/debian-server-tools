# Horde

### Installation

First run `/webserver/add-site.sh`

```bash
apt-get install -y gettext php-pear aspell-hu
su --login horde

# Local PEAR installation
HORDE_PEARCONF="/home/horde/website/pear.conf"
pear config-create /home/horde/website "$HORDE_PEARCONF"
pear -C "$HORDE_PEARCONF" install pear
pear -C "$HORDE_PEARCONF" channel-update pear.php.net
echo -e "#\!/bin/bash\n/home/horde/website/pear/pear -C ${HORDE_PEARCONF%.conf}-system.conf -c ${HORDE_PEARCONF} \"\$@\"" \
    > /home/horde/website/horde-pear
chmod +x /home/horde/website/horde-pear
# Test
/home/horde/website/horde-pear config-show | grep -i "config"

# Horde installation
# @FIXME PHP7 needs "--force"
/home/horde/website/horde-pear channel-discover pear.horde.org
/home/horde/website/horde-pear install horde/horde_role
# ENTER /home/horde/website/html
/home/horde/website/horde-pear run-scripts horde/Horde_Role
# Don't build C extensions -> install apt packages
/home/horde/website/horde-pear install --nobuild --force horde/horde

# Additional Horde packages
# Tests, Open TNEF, Pretty URL-s, Gravatar support, IMP
/home/horde/website/horde-pear install --nobuild --force horde/Horde_Test \
    horde/Horde_Mapi horde/Horde_Routes horde/Horde_Service_Gravatar
# Applications
/home/horde/website/horde-pear install --force \
    horde/imp horde/ingo horde/turba horde/Horde_ActiveSync
# phpseclib packages
/home/horde/website/horde-pear channel-discover phpseclib.sourceforge.net
/home/horde/website/horde-pear install phpseclib.sourceforge.net/File_ASN1

# Predis (Redis client)
/home/horde/website/horde-pear channel-discover pear.nrk.io
/home/horde/website/horde-pear install nrk/Predis

# Create database tables
PHP_PEAR_SYSCONF_DIR="/home/horde/website" php -d "include_path=.:/home/horde/website/pear/php" \
    /home/horde/website/pear/horde-db-migrate
```

##### Apache configuration

Copy contents of `.htaccess` to vhost config.

##### PHP-FPM configuration

```ini
; Horde
;php_admin_value[open_basedir] =
; default = ".:/usr/share/php:/usr/share/pear"
php_admin_value[include_path] = ".:/home/horde/website/pear/php"
; PEAR
env[PHP_PEAR_SYSCONF_DIR] = /home/horde/website
env[TMPDIR] = /home/horde/website/tmp
```

##### Extensions

- https://pecl.php.net/package/geoip
- https://packages.debian.org/source/stable/php-horde-lz4
- https://pecl.php.net/package/imagick
- https://packages.debian.org/stretch/php7.0-tidy

`apt-get install -y php-geoip php-horde-lz4 php-imagick php7.0-tidy`

Enable only for horde's FPM pool?

### Configuration

```bash
cp -v config/conf.php.dist config/conf.php
```

```php
// Assume SSL
$conf['use_ssl'] = 1;
$conf['server']['port'] = 443;
// Allow webserver to read cached files in /static
$conf['umask'] = 037;
// Temporarily enable tests
$conf['testdisable'] = false;
// Pretty URL-s
$conf[urls][pretty] = true;
// Add new From: addresses
$conf[user][verify_from_addr] = true;
```

Add `hordeadmin` IMAP user.

@TODO      php-env-check.php from /test.php

Copy `/mail/horde/*` files.

Update page title: `msgfmt -o locale/en/LC_MESSAGES/horde.mo locale/en/LC_MESSAGES/horde.po`

### Setup account defaults

"Show Advanced"

* /services/prefs.php?app=horde&group=identities
* /services/prefs.php?app=horde&group=language
* /services/prefs.php?app=horde&group=display

- /services/prefs.php?app=imp&group=sentmail
- /services/prefs.php?app=imp&group=addressbooks
- /services/prefs.php?app=imp&group=delmove
- /services/prefs.php?app=imp&group=spamreport
- /services/prefs.php?app=imp&group=newmail
- /services/prefs.php?app=imp&group=mboxdisplay
- /services/prefs.php?app=imp&group=folderdisplay

### Upgrade

```bash
./horde-pear clear-cache
./horde-pear -vvv update-channels
./horde-pear upgrade PEAR
./horde-pear list -c horde
./horde-pear list-upgrades
./horde-pear -vvv upgrade --nobuild --onlyreqdeps -c horde
#./horde-pear -vvv upgrade --nobuild --alldeps -c horde

# $HORDE_URL/admin/config/
# Upgrade database schema
# Upgrade configuration
```
