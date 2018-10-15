# Composer versions and constraints

### Tilde Version Range

Last (minor) version number may increase: "~4.4" means ">=4.4 <5.0.0"  
"~4.4.1" means ">=4.4.1 <4.5"

```json
  "wpackagist-plugin/advanced-custom-fields": "~4.4",
```

### Caret Version Range

Major version may not change, allow non-breaking updates: "^1.6.1" means ">=1.6.1 <2.0.0"  
For pre-1.0 versions: "^0.3" means ">=0.3.0 <0.4.0"

```json
  "wpackagist-plugin/posts-to-posts": "^1.6.1"
```

Experiment on http://jubianchi.github.io/semver-check/

Live testing https://semver.mwl.be/
