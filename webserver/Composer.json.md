### Composer versions and constraints

```json
{
  "name": "szepeviktor/wordpress",
  "description": "Install WordPress by using composer packages.",
  "license": "MIT",

  "require": {
    # Exact Version Constraint
    "php": "=7.0.26",

    # Version Range
    "johnpbloch/wordpress": ">= 4.8 < 4.8.5",

    # Wildcard Version Range
    "timber/timber": "1.3.*",

    # Tilde Version Range
    # Last version number may increase: "~4.4" == ">=4.4 <5.0.0"
    # "~4.4.1" == ">=4.4.1 <4.5"
    "wpackagist-plugin/advanced-custom-fields": "~4.4",

    # Caret Version Range
    # Major version may not change, allow non-breaking updates: "^1.6.1" == ">=1.6.1 <2.0.0"
    # For pre-1.0 versions: "^0.3" == ">=0.3.0 <0.4.0"
    "wpackagist-plugin/posts-to-posts": "^1.6.1"
  }
}
```

Experiment on http://jubianchi.github.io/semver-check/

Live testing https://semver.mwl.be/
