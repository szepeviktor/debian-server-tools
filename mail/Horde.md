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
- https://packages.debian.org/stretch/php7.2-tidy

`apt-get install -y php-geoip php-horde-lz4 php-imagick php7.2-tidy`

Enable only for horde's FPM pool?

### Configuration

```bash
cp -v config/conf.php.dist config/conf.php
```

```php
// Horde conf.php

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

// IMP conf.php

// Mail composition
$conf['compose']['use_vfs'] = false;
// Linked attachments
$conf['compose']['link_attachments_notify'] = true;
$conf['compose']['link_attach_threshold'] = 5242880;
$conf['compose']['link_attach_size_limit'] = 26214400;
$conf['compose']['link_attach_size_hard'] = 26214400;
$conf['compose']['link_attachments'] = true;
// Attachments
$conf['compose']['attach_size_limit'] = 4194304; // post_max_size = 4M and upload_max_filesize = 4M
$conf['compose']['attach_count_limit'] = 20;
// Others
$conf['compose']['reply_limit'] = 200000;
$conf['compose']['ac_threshold'] = 3;
$conf['compose']['htmlsig_img_size'] = 30000;
```

Add `hordeadmin` (IMAP) user.

@TODO php-env-check.php from Horde's `/test.php`

Copy `/mail/horde/*` files.

Copy logrotate configuration.

Update page title: `msgfmt -o locale/en/LC_MESSAGES/horde.mo locale/en/LC_MESSAGES/horde.po`

Log reporter: `./install.sh mail/horde/_bin/horde-report.sh`

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

### Exchange ActiveSync compatible service

```apache
Alias /Microsoft-Server-ActiveSync ${DOCUMENT_ROOT}/rpc.php
Alias /microsoft-server-activesync ${DOCUMENT_ROOT}/rpc.php
Alias /autodiscover/autodiscover.xml ${DOCUMENT_ROOT}/rpc.php
Alias /Autodiscover/Autodiscover.xml ${DOCUMENT_ROOT}/rpc.php
Alias /AutoDiscover/AutoDiscover.xml ${DOCUMENT_ROOT}/rpc.php
```

### Upgrade

```bash
script --timing=../horde-pear.time ../horde-pear.script
./horde-pear clear-cache
./horde-pear -vvv update-channels
./horde-pear upgrade PEAR
./horde-pear list -c horde
./horde-pear list-upgrades
./horde-pear -vvv upgrade --nobuild --onlyreqdeps -c horde
#./horde-pear -vvv upgrade --nobuild --alldeps -c horde
./horde-pear list-upgrades
exit
service php7.2-fpm reload

# Browse to: https://HORDE-URL/admin/config/
# Upgrade database schema
# Upgrade configuration
```

### Debug

```php
Horde::logMessage($result, __FILE__, __LINE__, PEAR_LOG_ERR);
```
