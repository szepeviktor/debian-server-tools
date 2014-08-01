#!/bin/bash
#
# Build suhosin patch for PHP 5.4 on Debian squeeze and wheezy
#
# VERSION       :0.1
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# UPSTREAM      :http://www.php-security.net/archives/8-Suhosin-0.9.34-dev-installation-howto.html


# SOURCES
# https://github.com/stefanesser/suhosin/archive/1fba865ab73cc98a3109f88d85eb82c1bfc29b37.zip
# https://raw.github.com/jani/suhosin/e8beb4f50fa997c0ea4b923677deb275cc7660e8/rfc1867.c
# https://raw.github.com/blino/suhosin/117b6aa6efec61afaa1431c698dad8eb553b55f5/session.c

die() {
    local RET="$1"
    shift
    echo -e $@ >&2
    exit "$RET"
}

SUHO="stefanesser-suhosin-1fba865"

# too nice PHPVER="$(php -r '$v=explode(".",PHP_VERSION);echo $v[0].".".$v[1];')"
PHPVER="$(php -r 'echo substr(PHP_VERSION,0,3);')"
[ "$PHPVER" = 5.4 ] || die 1 "only for PHP 5.4"

apt-get -y install build-essential make php5-common php5-dev php5-cli || die 2 "cannot install requirements"

cd /usr/local/src || die 3 "no /usr/local/src"
tar zxvf "./${SUHO}/${SUHO}.tar.gz" || die 4 "extract failure"
cd "$SUHO" || die 5 "no dir in tarball"

phpize || die 6 "phpize error"
./configure || die 7 "configure error"
make || die 8 "make error"
make test || die 9 "test(s) failed"
make install || die 10 "installation error"

cp -v suhosin.ini /etc/php5/conf.d/ || die 11 "cannot copy extension"

echo "RESULT"
echo "======"
php -v

