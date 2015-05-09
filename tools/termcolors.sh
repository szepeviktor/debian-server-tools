#!/bin/bash
#
# Display samples of all 16/256 terminal colors and attributes.
#
# Start:          \033[
# Separator:      ;
# End:            m
# http://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes

TCOLORS="0,Black 1,Red 2,Green 3,Yellow 4,Blue 5,Magenta 6,Cyan 7,White 9,Default"
TATTRS="0,Reset 1,Bright 2,Dim 3,Italic 4,Underscore 5,Blink 6,Blink2 7,Reverse"
TATTR="\033["
# Debug
#TATTR="←["

TRESET="${TATTR}0m"
WHITE_ON_BLACK="${TATTR}0;37;40m"
BLUE_ON_BLACK="${TATTR}0;34;40m"

Reset() {
    printf "${TATTR}0m"
}

PrintColors() {
    local ID="${1%,*}"
    local COLOR="${1#[0-9],}"
    local MODE="$2"
    local DEFAULT="$3"

    if [ "$ID" == 0 ] && [ "$MODE" == 3 ]; then
        # White background for black foreground.
        SHIM=";47"
    elif [ "$ID" == 0 ] && [ "$MODE" == 4 ]; then
        # White foreground for black background.
        SHIM=";37"
    else
        SHIM=""
    fi
    printf " ${TATTR}0;${DEFAULT};${MODE}${ID}${SHIM}m %12s " "$COLOR"
    printf "${TATTR}1;${MODE}${ID}${SHIM}m %12s ${TATTR}0;${DEFAULT}m\n" "$COLOR"
}

Reset
echo "8 terminal attributes (0-7)"
for C in ${TATTRS}; do
    PrintColors "$C" "" "39;49"
done

Reset
echo "18 foreground colors (30-37)"
for C in ${TCOLORS}; do
    PrintColors "$C" 3 49
done

Reset
echo "18 background colors (40-47)"
for C in ${TCOLORS}; do
    PrintColors "$C" 4 30
done

Reset
echo "256 foreground colors (38)"
for X in $(seq 0 15); do
    for Y in $(seq 0 15); do
        printf "${TATTR}0;38;5;%sm %-3s■ ${TATTR}0m" "$((16 * X + Y))" "$((16 * X + Y))"
    done
    echo
done

Reset
echo "256 background colors (48)"
for AH in $(seq 0 15); do
    for AL in $(seq 0 15); do
        printf "${TATTR}0;48;5;%sm %3s ${TATTR}0m" "$((16 * AH + AL))" "$((16 * AH + AL))"
    done
    echo
done

Reset
echo "512 random color combinations (0,1 × 38 × 48)"
for AH in $(seq 0 15); do
    for AL in $(seq 0 31); do
        printf "${TATTR}%s;38;5;%s;48;5;%sm ■ ${TATTR}0m" "$((RANDOM % 2))" "$((RANDOM % 256))" "$((RANDOM % 256))"
    done
    echo
done

Reset
