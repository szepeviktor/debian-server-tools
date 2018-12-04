#!/bin/bash
#
# Linux package versions and possible updates - apt, python, pear, pecl, node.js, ruby gems and java JRE.
#
# VERSION       :0.4.1
# DATE          :2014-09-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/package-versions.sh
# DEPENDS       :pip-review-debian.patch
# CRON-MONTHLY  :/usr/local/sbin/package-versions.sh | mail -E -S from="pkgs <root>" -s "[admin] package versions and updates" root


h1()
{
    local MAXWIDTH="$(( 26 - 2 ))"
    local MSG="$*"
    local MSG_SIZE="${#MSG}"
    local LEFT_SIDE="$(( (MAXWIDTH + MSG_SIZE + 1) / 2 ))"
    local RIGHT_SIDE="$(( MAXWIDTH - LEFT_SIDE ))"

    printf '\n/************************\\\n'
    printf '|%*s%*s|\n' "$LEFT_SIDE" "$MSG" "$RIGHT_SIDE" " "
    printf '\\************************/\n'
}

v()
{
    # $1 is optional
    echo -n "[ver] $1"
}

get_java_latest()
{
    local BUNDLEURL
    local JAVAWEBVERSION
    local JAVALATEST_MAJOR
    local JAVALATEST_MINOR

    BUNDLEURL="$(wget -qO- "https://www.java.com/en/download/linux_manual.jsp" \
        | grep -m 1 -i 'Linux x64' \
        | grep -o 'http://.*download.*?BundleId=[0-9]\+')"

    JAVAWEBVERSION="$(wget -q -S --max-redirect=0 "$BUNDLEURL" 2>&1 \
        | sed -n -e 's|.* Location: http://.*oracle\.com/.*/jre-\([^-]\+\)-linux-x64.tar.gz\?.*|\1|p')"

    JAVALATEST_MAJOR="1.${JAVAWEBVERSION%%u*}"
    JAVALATEST_MINOR="0${JAVAWEBVERSION##*u}"
    JAVALATEST_MINOR="${JAVALATEST_MINOR:(-2)}"

    # 1.7.0_55, 1.8.0_05
    echo "${JAVALATEST_MAJOR}.0_${JAVALATEST_MINOR}"
}

get_java_current()
{
    java -version 2>&1 \
        | grep '^java version' | cut -d '"' -f 2
}

get_java_update()
{
    local JAVA_LATEST
    local JAVA_CURRENT

    JAVA_LATEST="$(get_java_latest)"
    JAVA_CURRENT="$(get_java_current)"

    test -z "$JAVA_LATEST" && return 1
    test -z "$JAVA_CURRENT" && return 2

    if [ "$JAVA_LATEST" == "$JAVA_CURRENT" ]; then
        echo "java-jre (${JAVA_CURRENT})"
    else
        echo "java-jre==${JAVA_LATEST} is available (you have ${JAVA_CURRENT})"
    fi
}

# Everything in English
export LC_ALL="C"

h1 "system information"
uname --all

if which apt-get aptitude &>/dev/null; then
    h1 "apt"
    v; apt-get --version | head -n 1
    aptitude update --quiet=2 || echo "apt update failure."
    aptitude --disable-columns --display-format "%p" search '?upgradable' || echo "apt package listing error."
fi

if which python pip-review-debian &>/dev/null; then
    h1 "python"
    v; python --version 2>&1
    pip-review-debian 2>&1 || echo "python package list error."
fi

if which pear &>/dev/null; then
    # pear + pecl
    h1 "PHP extensions"
    v; pear version | head -n 1
    pear update-channels >/dev/null && pear list-upgrades || echo "pear update failure."
fi

## TODO Perl
# DEPENDS       :cpan App::pmodinfo
# list all:     pmodinfo -l
# updates:      echo n | pmodinfo -u

if which npm &>/dev/null; then
    h1 "node.js"
    v "npm"; npm --version
    npm -g outdated 2>/dev/null || echo "node.js update failure."
fi

if which gem &>/dev/null; then
    h1 "ruby gem"
    v "gem"; gem --version
    gem outdated -u || echo "ruby gem update failure."
fi

if which java &>/dev/null; then
    h1 "java jre"
    get_java_update || echo "java jre update failure."
fi
