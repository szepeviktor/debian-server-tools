#!/bin/bash
#
# Find Unicode Format characters in the database.
#
# VERSION       :0.1.0
# DOCS          :https://www.unicode.org/reports/tr44/#GC_Values_Table
# REFS          :https://unicode.org/charts/PDF/U2000.pdf

set -e

# Search only
wp db search '\p{Cf}' --regex --regex-flags=u --all-tables
# Prepare for removal
wp search-replace '\p{Cf}' 'Cf#Format' --regex --regex-flags=u --all-tables --precise --log --dry-run
# Remove
wp search-replace '\p{Cf}' '' --regex --regex-flags=u --all-tables --precise --log
