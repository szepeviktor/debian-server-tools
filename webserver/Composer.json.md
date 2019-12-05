# Composer versions and constraints

https://getcomposer.org/doc/articles/versions.md#next-significant-release-operators

### Tilde Version Range

Last (minor) version number may increase.

| Constrain | Version range |
| --------- | ------------- |
| `~4.4` | `>=4.4 <5.0.0` |
| `~4.4.1` | `>=4.4.1 <4.5.0` |

```json
    "wpackagist-plugin/advanced-custom-fields": "~4.4",
```

### Caret Version Range

Major version may not change, allow non-breaking updates.

| Constrain | Version range |
| --------- | ------------- |
| `^1.6.1` | `>=1.6.1 <2.0.0` |
| **for pre-1.0 versions** `^0.3` | `>=0.3.0 <0.4.0` |

```json
    "wpackagist-plugin/posts-to-posts": "^1.6.1"
```

Experiment on http://jubianchi.github.io/semver-check/

Live testing https://semver.mwl.be/#!?package=peterkahl%2Fcurl-master
