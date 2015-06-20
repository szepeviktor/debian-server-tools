#!/bin/bash
#
# Set terminal title to hostname.

TERM_TITLE="$(hostname -f)"

# man terminfo
echo -n "$(tput tsl)${TERM_TITLE}$(tput fsl)"
