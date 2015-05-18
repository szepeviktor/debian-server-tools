#/bin/dash
#
# Generate jpeg-archive Debian package.
#
# VERSION       :0.2
# DATE          :2015-05-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install pbuilder

# Usage
#
# pbuilder --execute --bindmounts /var/cache/pbuilder/result -- ./pbuilder_php5-suhosin-extension.sh
#
# Results
#
# ls -l /var/cache/pbuilder/result

set -x

RESULTS="/var/cache/pbuilder/result"

# Prerequisites
#sed -i 's/main$/main contrib non-free/g' /etc/apt/sources.list
apt-get update && apt-get install -y build-essential git php5-dev fakeroot
cd /usr/src/

# Build suhosin
git clone https://github.com/stefanesser/suhosin && cd suhosin/pkg/
export SUHOSIN_VERSION="$(grep -o 'SUHOSIN_EXT_VERSION\s*".*"' ../php_suhosin.h|cut -d'"' -f2|sed 's/-dev/-1~dev/')"
yes "y" | ./build_deb.sh "$SUHOSIN_VERSION" || exit 1
ls ./php5-suhosin-extension*.deb || exit 2

# Results
mv -v ./php5-suhosin-extension*.deb "$RESULTS"

cd ../../
