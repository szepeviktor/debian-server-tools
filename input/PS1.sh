#!/bin/bash
#
# Set PS1 prompt.


## Features
#
# - user/root
# - 16/256
# - last comand exit code
# - last command's order number
# - .git status

ps1_elements() {
    nonprinting="\["
    nonprintingend="\]"

    bell="\a"
    usdate="\d"
    escape="\e"
    hostname="\h"
    hostnamefull="\H"
    numberofjobs="\j"
    terminaldevice="\l"
    newline="\n"
    return="\r"
    shell="\s"
    timefull24="\t"
    timefull12="\T"
    timeampm="\@"
    time24="\A"
    username="\u"
    bashversion="\v"
    bashrelease="\V"
    workingdir="\w"
    workingdirbasename="\W"
    historynumber="\!"
    commandnumber="\#"
    hashdollar="\$"
    backslash="\\"

    #\D{format} -> strftime
    #\nnn -> octal ASCII
}

fast_chr() {
    local __octal
    local __char

    printf -v __octal '%03o' "$1"
    printf -v __char \\${__octal}
    REPLY=${__char}
}

unichr() {
    local c=$1  # ordinal of char
    local l=0   # byte ctr
    local o=63  # ceiling
    local p=128 # accum. bits
    local s=''  # output string

    (( c < 0x80 )) && { fast_chr "$c"; echo -n "$REPLY"; return; }

    while (( c > o )); do
        fast_chr $(( t = 0x80 | c & 0x3f ))
        s="$REPLY$s"
        (( c >>= 6, l++, p += o+1, o>>=1 ))
    done

    fast_chr $(( t = p | c ))
    echo -n "$REPLY$s"
}

dumpchars() {
    ## test harness
    for (( i=0x2500; i<0x2b5a; i++ ))
    do
        unichr "$i"
        echo -n " "
    done
}

term_colors() {
    black="$(tput setaf 0)"
    red="$(tput setaf 1)"
    green="$(tput setaf 2)"
    yellow="$(tput setaf 3)"
    blue="$(tput setaf 4)"
    magenta="$(tput setaf 5)"
    cyan="$(tput setaf 6)"
    white="$(tput setaf 7)"

    blackBG="$(tput setab 0)"
    redBG="$(tput setab 1)"
    greenBG="$(tput setab 2)"
    yellowBG="$(tput setab 3)"
    blueBG="$(tput setab 4)"
    magentaBG="$(tput setab 5)"
    cyanBG="$(tput setab 6)"
    whiteBG="$(tput setab 7)"

    bold="$(tput bold)"
    boldEND="$(tput dim)"
    bright="$(tput bold)"
    brightEND="$(tput dim)"
    underline="$(tput smul)"
    underlineEND="$(tput rmul)"
    reverse="$(tput rev)"
    reset="$(tput sgr0)"

    #dumpchars
    #echo "${reset}${blueBG}${white}Text comes here!${reset}"
}

ps1_elements
term_colors

#    PS1="${reset}[${bold}${yellow}${username}${reset}\
#${cyan}@${underline}${hostname}${reset}:\
#${bold}${white}${blueBG}${workingdir}${reset}:\
#${white}${commandnumber}${reset}\
#${newline}${hashdollar} "

#PROMPT_COMMAND='if [ $? = 0 ]; then DOLLAR_COLOR="\033[0m"; else DOLLAR_COLOR="\033[31m"; fi'

### This Changes The PS1 ###
export PROMPT_COMMAND=__prompt_command  # Func to gen PS1 after CMDs

function __prompt_command() {
    local RET="$?"

    # Empty prompt
    PS1=""

    if [ "$RET" != 0 ]; then
       # Can add `kill -l $?` to test to filter backgrounded
       PS1+="${white}${redBG}${RET}${reset}"
    fi
}
