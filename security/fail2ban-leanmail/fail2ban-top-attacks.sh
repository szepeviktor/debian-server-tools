#!/bin/bash

logsearch.sh -e no_wp_here  |grep -o "no_wp_here\S\+"  |sort|uniq -c; \
logsearch.sh -e bad_request |grep -o "bad_request\S\+" |sort|uniq -c; \
logsearch.sh -e wpf2b       |grep -o "wpf2b\S\+"       |sort|uniq -c
