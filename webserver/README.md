### File revving on nginx

```nginx
location ~* ^(.+)\.\d\d+\.(js|css|png|jpg|jpeg|gif|ico)$ {
    try_files $1.$2 /index.php?$args;
}
```

### Remove all comments and indentation from a PFP script

```bash
php -w SCRIPT.php | sed 's/;/;\n/g'
```
