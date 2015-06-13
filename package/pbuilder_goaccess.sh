#/bin/dash
#
# Generate goaccess Debian package by hand.
#
# VERSION       :0.1
# DATE          :2015-06-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install pbuilder

# Usage
#
# pbuilder --login --bindmounts /var/cache/pbuilder/result
#
# Results
#
# ls -l /var/cache/pbuilder/result

exit 0

apt-get install -y devscripts debhelper libncurses5-dev libncursesw5-dev libglib2.0-dev libgeoip-dev

cd /usr/local/src/
# https://packages.debian.org/sid/goaccess
dget -ux http://http.debian.net/debian/pool/main/g/goaccess/goaccess_0.8.3-1.dsc
# https://github.com/allinurl/goaccess/releases
wget https://github.com/allinurl/goaccess/archive/v0.9.1.tar.gz
tar xf v*.tar.gz

# Copy in /debian
cd goaccess-0.9.1/

# https://github.com/allinurl/goaccess/pull/257
sed -i 's/^CFLAGS="$CFLAGS -pthread"$/CFLAGS="-pthread"/' configure.ac

# Autoconf
autoreconf -fiv

# configure options
cat <<RULES >> debian/rules
override_dh_auto_configure:
$(echo -ne "\t")dh_auto_configure -- --enable-geoip --enable-utf8
RULES

# Changlelog entry
dch -d

# Build package
dpkg-buildpackage -b
