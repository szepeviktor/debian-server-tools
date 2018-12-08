#!/bin/bash
#
# Add a user with password and SSH key.
#
# VERSION       :0.2.0
# DATE          :2016-09-03
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install sudo

# Add user with sudo privilege, password and SSH key will be asked for
#
#     add-user.sh -s username
#
# Add user with password and piped SSH key
#
#     cat public.key | add-user.sh -p password username
#
# Add user with expired password
#
#     add-user.sh -e username

# Entry point
main()
{
    local U
    # From /etc/adduser.conf
    local NAME_REGEX="^[a-z][-a-z0-9_]*\$"
    local SUDO="no"
    local EXPIRED="no"
    local PASSWORD=""
    local OPT
    local HOME_DIR
    local SSH_DIR
    local SSH_AUTHKEYS

    while getopts :sep: OPT; do
        case "$OPT" in
            s)
                SUDO="yes"
                ;;
            e)
                EXPIRED="yes"
                ;;
            p)
                PASSWORD="$OPTARG"
                ;;
            ?)
                echo "Invalid option (${OPT})" 1>&2
                exit 2
                ;;
        esac
    done

    shift "$((OPTIND - 1))"

    # Missing username
    test "$#" -eq 1

    # Last option is the username
    U="$1"

    # Check username
    [[ "$U" =~ ${NAME_REGEX} ]]

    if [ -n "$PASSWORD" ]; then
        # Add user with the specified password
        # GECOS: Full name,Room number,Work phone,Home phone
        printf '%s\n%s\n' "$PASSWORD" "$PASSWORD" | adduser --gecos "" "$U"

        # Forget about the password
        unset PASSWORD
    elif [[ -t 0 ]]; then
        # Add user by asking for the password
        adduser --gecos "" "$U"
    else
        # Add user without a password
        adduser --gecos "" --disabled-password "$U"
        # Not possible to change password
        EXPIRED="no"
    fi

    # Expire password, force the user to change his password
    if [ "$EXPIRED" == yes ]; then
        passwd -e "$U"
    fi

    # Create SSH directory
    HOME_DIR="$(getent passwd "$U" | cut -d ":" -f 6)"
    SSH_DIR="${HOME_DIR}/.ssh"
    mkdir --mode 0700 "$SSH_DIR"

    # File that contains the user's public keys for authentication
    SSH_AUTHKEYS="${SSH_DIR}/authorized_keys"

    # Is stdin a TTY?
    if [[ -t 0 ]]; then
        # Ask for the public key
        editor "$SSH_AUTHKEYS"
    else
        # Get public key from pipe
        cat >"$SSH_AUTHKEYS"
    fi

    # Add line end if necessary
    if [ -s "$SSH_AUTHKEYS" ] && [ "$(wc -l <"$SSH_AUTHKEYS")" == 0 ]; then
        echo >>"$SSH_AUTHKEYS"
    fi

    # Change owner of the SSH directory and its contents
    chown --recursive "${U}:${U}" "$SSH_DIR"

    # Display fingerprint
    ssh-keygen -l -v -f "$SSH_AUTHKEYS"

    # Add to sudoers group
    if [ "$SUDO" == yes ]; then
        adduser "$U" sudo
    fi

    # Exit status is that of the last command executed.
    exit
}

# Options
set -o errexit -o noglob -o nounset -o pipefail

# Call main
main "$@"
