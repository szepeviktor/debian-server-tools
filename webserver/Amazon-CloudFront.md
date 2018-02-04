# Set up origin pull CDN on Amazon CloudFront

### CDN settings

- Have CDN always serve files on HTTPS, redirect HTTP traffic to HTTPS
- Don't forward cookies
- Don't forward and base caching on query string

### Origin settings

- [CloudFront does not support ECC](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html)
  for origin connections
- Use `tiny-cdn` plugin for URL rewriting
- Set canonical HTTP header for CDN requests `Link: <https://example.com/path/image.jpg>; rel="canonical"`
- Don't let browsers send cookies to CDN on a subdomain
- Serve separate `robots.txt` for CDN
- Add `Host:` to both `robots.txt` files
- Add `Sitemap:` to both `robots.txt` files
- Log `X-Forwarded-For` in place of referer in `combined` log format
