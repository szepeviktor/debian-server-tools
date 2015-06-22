#!/bin/bash
#
# List all 256 colors.
#

tput sgr0

for BG in {0..255}; do
    printf "$(tput setab $BG;tput setaf 190)%-80d$(tput sgr0)\n" "$BG"
done
