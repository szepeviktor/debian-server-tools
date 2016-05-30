#!/bin/bash
#
# Draw a charter code table.
#

One_char() {
    local HIGH="$1"
    local LOW="$2"
    local -i DEC="$((16#${HIGH}${LOW}))"
    local CHAR="${HIGH}${LOW}"

    # Non-printable
    if [ "$DEC" -lt 32 ]; then
        CHAR="$(printf "\x$(printf "%x" "$((DEC + 64))")")"
        printf "0x${HIGH}${LOW} - %02d - ^${CHAR}" "$DEC"
    elif [ "$DEC" -eq 32 ]; then
        printf "0x${HIGH}${LOW} - %02d <SP>" "$DEC"
    else
        # hex - dec - char
        printf "0x${HIGH}${LOW} - %02d - \x${CHAR}" "$DEC"
    fi
}

for H2 in 8 9 A B C D E F; do
    for LO in 0 1 2 3 4 5 6 7 8 9 A B C D E F; do
        H1="$((16#${H2} - 8))"

        One_char "$H1" "$LO"
        echo -en "\t  "
        One_char "$H2" "$LO"
        echo
    done
done | pager
