#!/bin/bash
#
# Linux package versions and possible updates - apt, python, pear, pecl, node.js, ruby gems and java JRE.
#
# VERSION       :0.3
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/package-versions.sh
# DEPENDS       :https://github.com/farukuzun/pip-tools/commit/fde178cb6c80217f49e3fb178d21b05611076a1f
# CRON-MONTHLY  :/usr/local/sbin/package-versions.sh | mailx -s "[admin] package versions and updates" -S from="pkgs <cron.monthly>" root


h1() {
        local MAXWIDTH="$(( 26 - 2 ))"
        local MSG="$*"
        local MSG_SIZE="${#MSG}"
        local LEFT_SIDE="$(( (MAXWIDTH + MSG_SIZE + 1) / 2 ))"
        local RIGHT_SIDE="$(( MAXWIDTH - LEFT_SIDE ))"
        echo
        echo "/************************\\"
        printf "|%*s%*s|\n" "$LEFT_SIDE" "$MSG" "$RIGHT_SIDE" " "
        echo "\\************************/"
}

v() {
    echo -n "[ver] $1"
}

get_java_latest() {
    local BUNDLEURL="$(wget -qO- "https://www.java.com/en/download/linux_manual.jsp" \
        | grep -m1 -i "Linux x64" \
        | grep -o "http://.*download.*?BundleId=[0-9]\+")"

    local JAVAWEBVERSION="$(wget -qS --max-redirect=0 "$BUNDLEURL" 2>&1 \
        | sed -n 's|.* Location: http://.*sun\.com/.*/jre-\([^-]\+\)-linux-x64.tar.gz\?.*|\1|p')"

    local JAVALATEST_MAJOR="1.${JAVAWEBVERSION%%u*}"
    local JAVALATEST_MINOR="0${JAVAWEBVERSION##*u}"
    local JAVALATEST_MINOR="${JAVALATEST_MINOR:(-2)}"

    ## 1.7.0_55, 1.8.0_05
    JAVALATEST="${JAVALATEST_MAJOR}.0_${JAVALATEST_MINOR}"
}

get_java_current() {
    JAVACURRENT="$(java -version 2>&1 \
        | grep "^java version" | cut -d'"' -f2)"
    #'
}

get_java_update() {
    get_java_latest
    get_java_current

    [ -z "$JAVALATEST" ] && return 1
    [ -z "$JAVACURRENT" ] && return 2

    if [ "$JAVALATEST" = "$JAVACURRENT" ]; then
        echo "java-jre (${JAVACURRENT})"
    else
        echo "java-jre==${JAVALATEST} is available (you have ${JAVACURRENT})"
    fi
}

#########################################################

export LC_ALL=C

h1 "system information"
uname --all

h1 "apt"
v; apt-get --version | head -n 1
aptitude update --quiet=2 || echo "apt update failure"
aptitude --disable-columns --display-format "%p" search ?upgradable || echo "apt package listing error"

h1 "python"
v; python --version 2>&1
pip-review-debian 2>&1 || echo "python package list error"

# pear + pecl
h1 "PHP extensions"
v; pear version | head -n 1
pear update-channels > /dev/null && pear list-upgrades || echo "pear update failure"

h1 "node.js"
v "npm"; npm --version
npm -g outdated 2> /dev/null || echo "node.js update failure"

h1 "ruby gem"
v "gem"; gem --version
gem outdated -u || echo "ruby gem update failure"

h1 "java jre"
get_java_update  || echo "java jre update failure"

