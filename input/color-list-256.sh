#!/bin/bash
#
# List all 256 colors.
#

tput sgr0

for BG in {0..255}; do
    printf '%s%-80d%s\n' "$(tput setab "$BG"; tput setaf 190)" "$BG" "$(tput sgr0)"
done
