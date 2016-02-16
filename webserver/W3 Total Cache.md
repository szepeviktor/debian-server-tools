# How to debug "creating the minify cache" errors

1. Put the config directories under git.
1. Set up an hourly cron job to monitor

```bash
#!/bin/bash

cd /home/user/website/wp-content/w3tc-config
git status -s

cd /home/user/website/wp-content/cache/config
git status -s
```
