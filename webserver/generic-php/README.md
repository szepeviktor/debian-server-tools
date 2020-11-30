### Remove all comments and indentation from (compact) a PHP script

```bash
php -w SCRIPT.php | sed -e 's#;#;\n#g'
```

### Unserialize piped string in PHP

```bash
cat serialized.txt | php -r 'var_export(unserialize(stream_get_contents(STDIN)));echo "\n";'
```

### PHIVE repository

https://phar.io/data/repositories.xml
