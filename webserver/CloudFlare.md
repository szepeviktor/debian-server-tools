# Setup a website on the Cloudflare platform

Cloudflare has a data center in [Budapest](https://www.cloudflare.com/cdn-cgi/trace)!

1. Set up cloudflare.local Fail2ban action
1. Add new LogFormat
1. Create IPv4 address list
1. Set up mod_remoteip
1. Reload apache
1. Install [IP list update script](./cloudflare-ipv4-update.sh)

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

IPv4 list

```bash
wget -O /etc/apache2/conf-available/cloudflare-ipv4.list "https://www.cloudflare.com/ips-v4"
```

Apache mod_remoteip module. Add to each vhost config.

```apache
    # mod_remoteip - Cloudflare is trusted by us
    RemoteIPHeader CF-Connecting-IP
    RemoteIPTrustedProxyList conf-available/cloudflare-ipv4.list
```

`a2enmod remoteip && apache2ctl configtest && service apache2 reload`

See https://support.cloudflare.com/hc/en-us/articles/200170986-How-does-Cloudflare-handle-HTTP-Request-headers-

### CDN-only settings

Use a CNAME. May be the CNAME of *another* domain.

- Always serve files on HTTPS, and redirect HTTP traffic to HTTPS
- Don't forward cookies
- Don't forward and base caching on query string
- Turn AlwaysOnline off (makes `/` requests)

### CDN-only origin settings

- URL rewriting - `tiny-cdn` plugin
- Set canonical HTTP header for CDN requests - `Link: <https://example.com/path/image.jpg>; rel="canonical"`
- Serve separate `robots.txt` for CDN
- Log `X-Forwarded-For` - in place of referer in `combined` log format
- Don't let browsers send cookies to CDN on a subdomain
- Add `Host:` to both `robots.txt`-s

### Trace Report

[`https://example.com/cdn-cgi/trace`](https://support.cloudflare.com/hc/en-us/articles/200169986-Which-Cloudflare-data-center-do-I-reach-)

### Notes

Log format

```
%h            %l%u%t                           "%r"                       %>s %O "%{Referer}i" "%{User-Agent}i"
111.22.33.444 - - [12/Feb/2016:15:49:09 +0100] "GET /robots.txt HTTP/1.1" 200 634 "-" "Mozilla/5.0"
```

Just log CF-Connecting-IP header insecurely

```apache
# The contents of CF-Connecting-IP: header line(s) in the request sent to the server
# %l -> %{CF-Connecting-IP}i
LogFormat "%h %{CF-Connecting-IP}i %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" cloudflare
```

Redirection on non-https origin server

```apache
RewriteCond "%{HTTP:X-Forwarded-Proto}" "!=https" [OR]
```

### Security

Restrict access

- In Apache `RemoteIPTrustedProxyList`
- In Linux firewall on port 80 and 443 using an ipset

SSL encryption toward Cloudflare edges

[Origin CA](https://blog.cloudflare.com/cloudflare-ca-encryption-origin/#3clicommandlineinterfacelinuxonly)
