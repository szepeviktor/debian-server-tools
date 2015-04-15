### File revving on nginx

```nginx
location ~* ^(.+)\.\d\d+\.(js|css|png|jpg|jpeg|gif|ico)$ {
        try_files $1.$2 /index.php?$args;
    }
```
