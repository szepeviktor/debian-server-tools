# Setup a website on the CloudFlare platform

### Operation

Apache log format

```apache
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %{CF-Connecting-IP}i %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" cloudflare
LogFormat "%h %{remoteip-proxy-ip-list}n %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" cloudflareall
```

https://bz.apache.org/bugzilla/show_bug.cgi?id=58097

http://httpd.apache.org/docs/2.4/mod/mod_remoteip.html#processing

```
%h            %l%u%t                           "%r"                       %>s %O "%{Referer}i" "%{User-Agent}i"
111.22.33.444 - - [12/Feb/2016:15:49:09 +0100] "GET /robots.txt HTTP/1.1" 200 634 "-" "Mozilla/5.0"
```

@TODO

- nginx
- fail2ban
- WordPress
- cf_ip cron job

/etc/apache2/mods-enabled/remoteip.conf

```apache
# CloudFlare is trusted by us
RemoteIPHeader CF-Connecting-IP
RemoteIPTrustedProxy $(wget -qO- https://www.cloudflare.com/ips-v4|tr '\n' ' ')
```

@TODO `manual_update.sh` apache2ctl configtest && service apache2 reload

### Security

Restrict access: only in Apache `Require ip` / in Linux firewall

[Origin CA](https://blog.cloudflare.com/cloudflare-ca-encryption-origin/#3clicommandlineinterfacelinuxonly)

