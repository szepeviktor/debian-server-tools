# shellcheck shell=bash
#
# Common functions for debian-setup
#
# VERSION       :2.1.0

Error()
{
    echo "ERROR: $(tput bold;tput setaf 7;tput setab 1)${*}$(tput sgr0)" 1>&2
}

Is_installed()
{
    local PKG="$1"

    test "$(dpkg-query --showformat="\${Status}" --show "$PKG" 2>/dev/null)" == "install ok installed"
}
export -f Is_installed

Is_installed_regexp()
{
    local PKG="$1"
    local SEARCH="?and(?installed, ?name(${PKG}))"

    test -n "$(aptitude --disable-columns --display-format "%p" search "$SEARCH")"
}
export -f Is_installed_regexp

Pkg_install_quiet()
{
    DEBIAN_FRONTEND=noninteractive apt-get install -q -y "$@"
}
export -f Pkg_install_quiet

# Download architecture-independent packages
Getpkg()
{
    local P="$1"
    local R="${2:-sid}"
    local PKG_PAGE="https://packages.debian.org/${R}/all/${P}/download"
    local URL

    URL="$(wget -q -O- "$PKG_PAGE" | grep -o '[^"]\+ftp\.de\.debian\.org/debian[^"]\+\.deb')"

    test -z "$URL" && return 1

    (
        cd /root/dist-mod/ || return 1
        wget -nv -O "${P}.deb" "$URL"
        dpkg -i "${P}.deb"
    )
}
export -f Getpkg

# Install a script from debian-server-tools
Dinstall()
{
    (
        cd /usr/local/src/ || return 1
        if [ ! -d debian-server-tools ]; then
            git clone "https://github.com/szepeviktor/debian-server-tools.git"
        fi
        cd debian-server-tools/ || return 1

        ./install.sh "$@"
    )
}
export -f Dinstall

Data()
{
    #PYTHONIOENCODING="utf_8" shyaml "$@" </root/server.yml
    python3 /usr/local/bin/shyaml "$@" </root/server.yml
}
export -f Data
