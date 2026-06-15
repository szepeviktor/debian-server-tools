# HTTP response header categories

## Connection & Transport

:memo: Section 7 of \[RFC9110]

- `Upgrade`
- `Connection`

## Caching & Freshness

:memo: \[RFC9111]

- `Age`
- `Cache-Control`
- `ETag`
- `Expires`
- `Last-Modified`
- `Vary`

## Content & Representation Metadata

:memo: Section 8 of \[RFC9110]

- `Content-Encoding`
- `Content-Language`
- `Content-Length`
- `Content-Type`

## Request / Response Context

:memo: Section 10 of \[RFC9110]

MDN uses separate `Request context` and `Response context` group names.
Fetch Metadata headers (`Sec-Fetch-*`) are request headers, so they are out of scope here.

## Authentication & Authorization

:memo: Section 11 of \[RFC9110]

## Cookies & Session Management

:memo: \[RFC6265]

- `Set-Cookie`

## Security & Privacy

:memo: Section 12 of \[RFC9110], \[RFC6797], \[RFC8941]

- `Content-Security-Policy`
- `X-Content-Type-Options`
- `Strict-Transport-Security`

## CORS (Cross-Origin Resource Sharing)

:memo: [Fetch Living Standard – CORS](https://fetch.spec.whatwg.org/)

- `Access-Control-Allow-Origin`

## Redirects & Location

:memo: Section 15.5.2 of \[RFC9110]

## Proxies & Intermediaries

:memo: Section 7.6 of \[RFC9110]

- `Via`

## Server & Response Info

:memo: Sections 6 and 10 of \[RFC9110]

- `Date`
- `Server`

## Streaming, Range & Protocol Upgrades

:memo: Section 14 of \[RFC9110], \[RFC6455]

This category combines MDN groups `Range requests`, `Server-sent events`, `Transfer coding`, and `WebSockets`.

- `Accept-Ranges`
- `Content-Range`
- `Transfer-Encoding`

## Other / Non-standard / Deprecated

## See also

- https://www.iana.org/assignments/http-fields/http-fields.xhtml
- https://www.geeksforgeeks.org/web-tech/http-headers/
- https://github.com/mnot/redbot/blob/c47e907f0c76003fa6411e5a1ce0c9e35635d559/redbot/speak.py#L20-L27
- [MDN HTTP headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers)

```javascript
Array.from(document.querySelectorAll("h2 > a")).map(function(anchor){return anchor.innerText}).join(",");
// "Authentication,Caching,Conditionals,Connection management,Content negotiation,Controls,Cookies,CORS,Downloads,Integrity digests,Integrity policy,Message body information,Preferences,Proxies,Range requests,Redirects,Request context,Response context,Security,Fetch storage access headers,Server-sent events,Transfer coding,WebSockets,Other,Experimental headers,Non-standard headers,Deprecated headers,See also"
```
