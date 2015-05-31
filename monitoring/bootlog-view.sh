#!/bin/bash
#
# Repair ANSI escape charaters in boot log.
#
# LOCATION      :/usr/local/sbin/bootlog-view.sh
# DEPENDS       :apt-get install bootlogd less

sed 's/\^\[/\o33/g;s/\[1G\[/\[27G\[/' /var/log/boot | less -r
