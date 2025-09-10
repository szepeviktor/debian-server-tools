# HTTP response header categories

## Connection & Transport

:memo: Section 7 of \[RFC9110]

- `Connection`
- `Upgrade`

## Caching & Freshness

:memo: \[RFC9111]

- `Cache-Control`
- `Expires`
- `Last-Modified`

## Content & Representation Metadata

:memo: Section 8 of \[RFC9110]

- `Content-Length`
- `Content-Type`

## Request Context & Navigation

:memo: Section 10 of \[RFC9110]

## Authentication & Authorization

:memo: Section 11 of \[RFC9110]

## Cookies & Session Management

:memo: \[RFC6265]

## Security & Privacy

:memo: Section 12 of \[RFC9110], \[RFC6797], \[RFC8941]

- `X-Content-Type-Options`
- `Strict-Transport-Security`

## CORS (Cross-Origin Resource Sharing)

:memo: [Fetch Living Standard – CORS](https://fetch.spec.whatwg.org/)

## Redirects & Location

:memo: Section 15.5.2 of \[RFC9110]

## Proxies & Intermediaries

:memo: Section 7.6 of \[RFC9110]

## Server & Response Info

:memo: Sections 6 and 10 of \[RFC9110]

- `Date`
- `Server`

## Streaming & Events (Range, SSE, WebSocket)

:memo: Section 14 of \[RFC9110], \[RFC6455]

- `Accept-Ranges`

## Miscellaneous / Non-standard

## See also

- https://www.iana.org/assignments/http-fields/http-fields.xhtml
- https://www.geeksforgeeks.org/web-tech/http-headers/
- https://github.com/mnot/redbot/blob/c47e907f0c76003fa6411e5a1ce0c9e35635d559/redbot/speak.py#L20-L27
- [MDN HTTP headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers)

```javascript
Array.from(document.querySelectorAll("h2 > a")).map(function(anchor){return anchor.innerText}).join(",");
// "Authentication,Caching,Conditionals,Connection management,Content negotiation,Controls,Cookies,CORS,Downloads,Integrity digests,Integrity policy,Message body information,Preferences,Proxies,Range requests,Redirects,Request context,Response context,Security,Server-sent events,Transfer coding,WebSockets,Other,Experimental headers,Non-standard headers,Deprecated headers,See also"
```
