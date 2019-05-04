#!/bin/bash
#
# List all files containing PHP classes.
#

grep -Eir '^\s*(((abstract|final)\s+)?class|interface|trait)\s'
