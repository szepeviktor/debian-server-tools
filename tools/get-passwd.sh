#!/bin/bash
#
# Obfuscated password input.
#
# VERSION       :0.2.1

Get_passwd()
{
    local PROMPT="$1"
    local REAL_PASSWD="$2"

    local PASSWD=""
    local KEY=" "
    local DEL
    local LETTER_POS
    local -a LETTERS=(
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        "," "." "-" "_" "=" "/" "%" "!" "+"
        A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        0 1 2 3 4 5 6 7 8 9
    )

    DEL="$(printf '\x7F')"

    echo -n "$PROMPT"

    # Loop until ENTER is pressed
    while [ -n "$KEY" ]; do
        IFS="" read -r -s -n 1 KEY
        if [ "$KEY" == "$DEL" ]; then
            if [ ${#PASSWD} -gt 0 ]; then
                PASSWD="${PASSWD:0:(-1)}"
            fi
        else
            PASSWD+="$KEY"
        fi

        # Display a random character instead of $KEY
        LETTER_POS="$(( RANDOM * ${#LETTERS[*]} / 32768 ))"
        echo -n "${LETTERS[$LETTER_POS]}"
    done

    echo

    # Return value
    test "$PASSWD" == "$REAL_PASSWD"
}

# Example
echo 'Type "alma"!'
if Get_passwd "Pwd? " "alma"; then
    echo "OK."
else
    echo "Invalid password."
fi
