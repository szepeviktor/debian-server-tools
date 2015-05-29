# Include in .bashrc
#DEPENDS       :apt-get install smartmontools

Hddtemp() {
    local DRIVE="$1"

    /usr/sbin/hddtemp --quiet --wake-up --numeric "$DRIVE" #| head --bytes=23
}

Smartctl_temp() {
    local DRIVE="$1"

    /usr/sbin/smartctl -A "$DRIVE" | grep -w "Temperature_Celsius" | awk '{print $10}'
}

All_hdd_temps() {
    local WHITE_ON_RED="$(tput setaf 7)$(tput setab 1)"
    local DEFAULT_COLOR="$(tput sgr0)"
    local GRAD="C"
    local TEMPERATURE

    # UTF-8
    if [ "$LANG" != "${LANG/UTF-8/}" ]; then
        GRAD="°C"
    fi

    for HARDDISK in /dev/sd? /dev/hd?; do
        [ -b "$HARDDISK" ] || continue
        TEMPERATURE="$(Smartctl_temp "$HARDDISK")"
        printf "%s:${WHITE_ON_RED}%s${GRAD}${DEFAULT_COLOR}  " "$HARDDISK" "$TEMPERATURE" >&2
    done
    [ -z "$TEMPERATURE" ] || echo >&2
}

# Physical server
tty --quiet && All_hdd_temps

# VPS
#tty --quiet && echo -e "                                    \033[1;37;41m no \033[0m physical disks" >&2
