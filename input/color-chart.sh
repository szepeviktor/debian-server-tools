#!/bin/bash
#
# Draw a chart of colors with corresponding `tput` arguments.
#

# Test text
TEXT='qYm'

tput sgr0
echo
# Background headers
echo "                 setab 0 setab 1 setab 2 setab 3 setab 4 setab 5 setab 6 setab 7"

# Foregrounds - rows
for FG_STRING in '  ' ' +' '0 ' '0+' '1 ' '1+' '2 ' '2+' '3 ' '3+' '4 ' '4+' '5 ' '5+' '6 ' '6+' '7 ' '7+'; do
    FG="${FG_STRING// /}"
    FG_COMMAND="     "
    COLOR="tput sgr0;"

    if [ -z "$FG" ]; then
        # First line underlined
        COLOR+="tput smul;"
        FG_COMMAND="smul "
    else
        if [ "${FG:(-1):1}" == "+" ]; then
            # Every second line bold
            FG="${FG:0:(-1)}"
            COLOR+="tput bold;"
            FG_COMMAND="bold "
        fi
        if [ -n "$FG" ]; then
            COLOR+="tput setaf ${FG};"
            FG_COMMAND="setaf"
        fi
    fi

    # Backgrounds - columns
    echo -n "${FG_COMMAND} ${FG_STRING} "
    echo -n "$(eval "$COLOR")  ${TEXT}  $(tput sgr0)"
    for BG in 0 1 2 3 4 5 6 7; do
        echo -n " $(eval "$COLOR";tput setab "$BG")  ${TEXT}  $(tput sgr0)"
    done
    echo
done
echo
