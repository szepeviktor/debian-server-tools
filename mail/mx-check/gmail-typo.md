# Gmail address typos

Usage: `grep -ix -f gmail-typo.grep address.list`

SLD prepend, append

`.\+@.\+gmail\.com`
`.\+@gmail.\+\.com`

TLD prepend, append

`.\+@gmail\..\+com`
`.\+@gmail\.com.\+`

TLD typo

`.\+@gmail\.[^c]om`
`.\+@gmail\.c[^o]m`
`.\+@gmail\.co[^m]`

TLD missing letter

`.\+@gmail\.co`
`.\+@gmail\.om`
`.\+@gmail\.cm`

SLD typo

`.\+@g[^m]ail\.com`
`.\+@gm[^a]il\.com`
`.\+@gma[^i]l\.com`
`.\+@gmai[^l]\.com`

SLD missing letter

`.\+@gail\.com`
`.\+@gmil\.com`
`.\+@gmal\.com`
`.\+@gmai\.com`

SLD swap

`.\+@gmila\.com`
`.\+@gmial\.com`
`.\+@gamil\.com`

[gmial.com is disposable??](https://github.com/martenson/disposable-email-domains/blob/master/disposable_email_blacklist.conf)

gamil.com delivers to webfaction.com??
