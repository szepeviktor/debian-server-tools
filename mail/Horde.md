### Install

```bash
H_PEARCONF="/home/horde/website/pear.conf"
pear config-create /home/horde/website "$H_PEARCONF"
pear -c "$H_PEARCONF" install pear
echo -e "#!/bin/bash\n/home/horde/website/pear/pear -c /home/horde/website/pear.conf \"\$@\"" > /home/horde/website/pear.sh
chmod +x /home/horde/website/pear.sh

/home/horde/website/pear.sh channel-discover pear.horde.org
/home/horde/website/pear.sh install horde/horde_role
/home/horde/website/pear.sh run-scripts horde/Horde_Role
/home/horde/website/pear.sh install -B horde/horde
# Create database tables
PHP_PEAR_SYSCONF_DIR=/home/horde/website php -d "include_path=.:/home/horde/website/pear/php" \
    /home/horde/website/pear/horde-db-migrate
```

Apache configuration:

```apache
SetEnv PHP_PEAR_SYSCONF_DIR /home/${SITE_USER}/website
```

PHP configuration:

```ini
; Horde - old: .:/usr/share/php:/usr/share/pear
php_admin_value[include_path] = .:/home/horde/website/pear/php
```

### Upgade


### Setup account defaults

"Show Advanced"

/services/prefs.php?app=horde&group=identities
/services/prefs.php?app=horde&group=language
/services/prefs.php?app=horde&group=display
/services/prefs.php?app=imp&group=sentmail
/services/prefs.php?app=imp&group=addressbooks
/services/prefs.php?app=imp&group=delmove
/services/prefs.php?app=imp&group=spamreport
/services/prefs.php?app=imp&group=newmail
/services/prefs.php?app=imp&group=mboxdisplay
/services/prefs.php?app=imp&group=folderdisplay


```css
/* Magnification */
body {
    font-size: 15px;
}

div.vpRow {
    height: 25px;
}

.horde-drowdown-str {
    height: 23px;
}

.horde-buttonbar {
    min-height: 36px;
    background-size: 1px 36px;
}
.horde-buttonbar li:hover,
.horde-buttonbar li.horde-active {
    background-size: 1px 36px;
}

.horde-buttonbar li {
    height: 28px;
    background-size: 1px 36px;
}
.horde-table-header,
table.horde-table thead tr,
table.horde-table th {
    background-size: 1px 25px;
}
/* -- Magnification */
```

`config/hooks.php`

```php
class Horde_Hooks
{
    public function cssfiles($theme)
    {
        return array(
            '/var/www/horde/css/horde.css' => '/css/horde.css'
        );
    }

}
```
