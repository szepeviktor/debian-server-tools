#!/bin/bash
#
# Display samples of all 16/256 terminal colors and attributes.
#
# Start:          \033[
# Separator:      ;
# End:            m
# Docs:           http://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes

TCOLORS="0,Black 1,Red 2,Green 3,Yellow 4,Blue 5,Magenta 6,Cyan 7,White 9,Default"
TATTRS="0,Reset 1,Bright 2,Dim 3,Italic 4,Underscore 5,Blink 6,Blink2 7,Reverse"
TATTR='\033['
# Debug
#TATTR='←['

TRESET="${TATTR}0m"
#WHITE_ON_BLACK="${TATTR}0;37;40m"
#BLUE_ON_BLACK="${TATTR}0;34;40m"

Reset()
{
    printf '%b\n' "$TRESET"
}

PrintColors()
{
    local COLOR_CODE2="${1%,*}"
    local COLOR_NAME="${1#[0-9],}"
    # 3 - foreground, 4 - background
    local MODE="$2"
    local DEFAULT_COLOR="$3"

    if [ "$COLOR_CODE2" == 0 ] && [ "$MODE" == 3 ]; then
        # White background for black foreground.
        SHIM=";47"
    elif [ "$COLOR_CODE2" == 0 ] && [ "$MODE" == 4 ]; then
        # White foreground for black background.
        SHIM=";37"
    else
        SHIM=""
    fi
    printf " ${TATTR}0;${DEFAULT_COLOR};${MODE}${COLOR_CODE2}${SHIM}m %12s " "$COLOR_NAME"
    printf "${TATTR}1;${MODE}${COLOR_CODE2}${SHIM}m %12s ${TATTR}0;${DEFAULT_COLOR}m\\n" "$COLOR_NAME"
}

Reset
echo "8 terminal attributes (0-7)"
for C in ${TATTRS}; do
    PrintColors "$C" "" "39;49"
done

Reset
echo "18 foreground colors (30-37,39)"
for C in ${TCOLORS}; do
    PrintColors "$C" 3 49
done

Reset
echo "18 background colors (40-47,49)"
for C in ${TCOLORS}; do
    PrintColors "$C" 4 30
done

Reset
echo "256 foreground colors (38)"
for X in {0..15}; do
    for Y in {0..15}; do
        printf "${TATTR}0;38;5;%sm %3s■ " "$((16 * X + Y))" "$((16 * X + Y))"
    done
    Reset
done

Reset
echo "256 background colors (48) with negative foreground color"
for AH in {0..15}; do
    for AL in {0..15}; do
        printf "${TATTR}0;38;5;%s;48;5;%sm %3s  " "$((255 - (16 * AH + AL)))" "$((16 * AH + AL))" "$((16 * AH + AL))"
    done
    Reset
done

Reset
echo "512 random color combinations (0-1; 38; 48)"
for AH in {0..15}; do
    for AL in {0..31}; do
        #printf "${TATTR}%s;38;5;%s;48;5;%sm ■ ${TATTR}0m" "$((RANDOM % 2))" "$((RANDOM % 256))" "$((RANDOM % 256))"
        printf "${TATTR}%s;38;5;%s;48;5;%sm a " "$((RANDOM % 2))" "$((RANDOM % 256))" "$((RANDOM % 256))"
    done
    Reset
done

echo
