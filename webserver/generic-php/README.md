### Remove all comments and indentation from (compact) a PHP script

```bash
php -w SCRIPT.php | sed -e 's/;/;\n/g'
```

### Unserialize piped string in PHP

```bash
cat serialized.txt | php -r '$s="";while(false!==($l=fgets(STDIN))){$s.=$l."\n";}var_export(unserialize($s));echo "\n";'
```

