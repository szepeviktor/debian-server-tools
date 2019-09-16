# Google Tag Manager

JavaScript URL: `https://www.googletagmanager.com/gtm.js?id=GTM`

Extract JSON object

```bash
sed -e '/^var data = {$/,/^};$/!d' | sed -e '1s/^var data = //; $s/;$//'
```

JavaScript events on elements with a certain HTML class

```bash
jq '."resource"."predicates"[] | select(."function" == "_cn") | ."arg1"'
```

To be injected HTML snippets

```bash
jq '."resource"."tags"[]'
```
