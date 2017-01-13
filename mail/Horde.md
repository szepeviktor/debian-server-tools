### Install

```bash
H_PEARCONF="/home/horde/website/pear.conf"
pear config-create /home/horde/website "$H_PEARCONF"
pear -c "$H_PEARCONF" install pear
echo -e "#!/bin/bash\n/home/horde/website/pear/pear -c ${H_PEARCONF} \"\$@\"" > /home/horde/website/pear.sh
chmod +x /home/horde/website/pear.sh

/home/horde/website/pear.sh channel-discover pear.horde.org
/home/horde/website/pear.sh install horde/horde_role
# Enter: /home/horde/website/html
/home/horde/website/pear.sh run-scripts horde/Horde_Role
/home/horde/website/pear.sh install -B horde/horde
# Open TNEF
/home/horde/website/pear.sh install -B horde/Horde_Mapi
# URL generation
/home/horde/website/pear.sh install -B horde/Horde_Routes
# Create database tables
PHP_PEAR_SYSCONF_DIR=/home/horde/website php -d "include_path=.:/home/horde/website/pear/php" \
    /home/horde/website/pear/horde-db-migrate
```

##### PHP configuration

```ini
; Horde - old: .:/usr/share/php:/usr/share/pear
php_admin_value[include_path] = .:/home/horde/website/pear/php
; PEAR
env[PHP_PEAR_SYSCONF_DIR] = /home/horde/website
env[TMPDIR] = /home/horde/website/tmp
```

##### Root files

- robots.txt
- favicon.ico
- ...

### Upgrade

```bash
#pear -vvv upgrade pear
pear -vvv update-channels
pear list -c horde
pear -vvv upgrade --nobuild --onlyreqdeps -c horde
pear -vvv upgrade --nobuild --alldeps -c horde
```

### Horde configuration

```php
// Allow webserver to read cached files in /static
$conf['umask'] = 037;
```

### Setup account defaults

"Show Advanced"

- /services/prefs.php?app=horde&group=identities
- /services/prefs.php?app=horde&group=language
- /services/prefs.php?app=horde&group=display
- /services/prefs.php?app=imp&group=sentmail
- /services/prefs.php?app=imp&group=addressbooks
- /services/prefs.php?app=imp&group=delmove
- /services/prefs.php?app=imp&group=spamreport
- /services/prefs.php?app=imp&group=newmail
- /services/prefs.php?app=imp&group=mboxdisplay
- /services/prefs.php?app=imp&group=folderdisplay

Customize login page title

@TODO .po location?, msgfmt -o .mo .po

```po
msgid ""
msgstr ""
"Project-Id-Version: Horde\n"
"Language: en\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8-bit\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

#: login.php:291 templates/login/login.inc:70
msgid "Log in"
msgstr "Log in to szepe.net"
```

### Magnification

`magnification.css`

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

form[action^="https://"] input.horde-default[type="submit"] {
    background-size: auto auto, auto 100%;
}
/* -- Magnification */
```

`config/hooks.php`

```php
class Horde_Hooks
{
    // Add magnification style
    public function cssfiles($theme)
    {
        return array(
            '/home/horde/website/html/css/magnification.css' => '/css/magnification.css'
        );
    }

}
```

### Virus alert

`imp/config/mime_drivers.local.php`

```php
    /* Zip file display. */
    'zip' => array(
        'handles' => array(
            'application/x-compressed',
            'application/x-zip-compressed',
            'application/zip'
        ),
        'icons' => array(
            //'default' => 'compressed.png'
            'default' => 'virus.png' // 49px × 20px
        )
    ),
```
