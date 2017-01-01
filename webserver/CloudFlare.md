# Setup a website on the CloudFlare platform

1. Set up cloudflare.local Fail2ban action
1. Add new LogFormat
1. Create IPv4 address list
1. Set up mod_remoteip
1. Reload apache
1. Install list update script

### Operation

- https://bz.apache.org/bugzilla/show_bug.cgi?id=58097
- http://httpd.apache.org/docs/2.4/mod/mod_remoteip.html#processing
- http://httpd.apache.org/docs/2.4/mod/mod_log_config.html

`/etc/apache2/apache2.conf`

```apache
# Original "combined"
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined

# Underlying peer IP address of the connection by mod_remoteip
# %h -> %a  %l -> %{c}a
LogFormat "%a %{c}a %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" mod_remoteip
# In overriding the client IP, the module stores the list of intermediate hosts in a remoteip-proxy-ip-list note
# %h -> %a  %l -> %{remoteip-proxy-ip-list}n
LogFormat "%a %{remoteip-proxy-ip-list}n %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" mod_remoteip_all
```

IPv4 list.

```bash
wget -O /etc/apache2/conf-available/cloudflare-ipv4.list "https://www.cloudflare.com/ips-v4"
```

Apache mod_remoteip module.

Create `/etc/apache2/mods-available/remoteip.conf` before `a2enmod remoteip`

```apache
# CloudFlare is trusted by us
RemoteIPHeader CF-Connecting-IP
RemoteIPTrustedProxyList conf-available/cloudflare-ipv4.list
```

`apache2ctl configtest && service apache2 reload`

### Notes

```
%h            %l%u%t                           "%r"                       %>s %O "%{Referer}i" "%{User-Agent}i"
111.22.33.444 - - [12/Feb/2016:15:49:09 +0100] "GET /robots.txt HTTP/1.1" 200 634 "-" "Mozilla/5.0"
```

Just log CF-Connecting-IP: header insecurely.

```apache
# The contents of CF-Connecting-IP: header line(s) in the request sent to the server
# %l -> %{CF-Connecting-IP}i
LogFormat "%h %{CF-Connecting-IP}i %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" cloudflare
```

### Security

@TODO Restrict access

- in Apache `Require ip`
- in Linux firewall on port 80,443

SSL encryption toward Cloudflare edges.

[Origin CA](https://blog.cloudflare.com/cloudflare-ca-encryption-origin/#3clicommandlineinterfacelinuxonly)
