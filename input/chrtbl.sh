#!/bin/bash
#
# Draw a charter code table.
#

Print_char()
{
    local HIGH="$1"
    local LOW="$2"
    local HEX="${HIGH}${LOW}"
    local -i DEC="$((16#${HEX}))"
    local CTRL_HEX
    local CHAR

    # Non-printable
    if [ "$DEC" -lt 32 ]; then
        printf -v CTRL_HEX '%02x' "$((DEC + 64))"
        printf -v CHAR '^%b' "\\x${CTRL_HEX}"
    elif [ "$DEC" -eq 32 ]; then
        CHAR="<SP>"
    elif [ "$DEC" -eq 127 ]; then
        CHAR="<DEL>"
    else
        printf -v CHAR '"%b"' "\\x${HEX}"
    fi

    printf '0x%2s - %03d - %s' "$HEX" "$DEC" "$CHAR"
}

for H2 in {8..9} {A..F}; do
    H1="$((16#${H2} - 8))"
    for LO in {0..9} {A..F}; do
        printf '%s  \t%s\n' "$(Print_char "$H1" "$LO")" "$(Print_char "$H2" "$LO")"
    done
done | iconv -c -f IBM437 -t UTF-8 | pager
