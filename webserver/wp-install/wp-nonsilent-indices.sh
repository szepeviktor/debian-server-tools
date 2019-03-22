#!/bin/bash
#
# List all non-empty index.php files.
#

SILENCE_IS_GOLDEN="<?php"

while read -r FILE; do
    if [ "$(/usr/bin/php -w "$FILE" | tr -d '[:space:]')" == "$SILENCE_IS_GOLDEN" ]; then
        continue;
    fi

    echo "Non-silent: ${FILE}" 1>&2
done < <(find . -type f -name index.php)
