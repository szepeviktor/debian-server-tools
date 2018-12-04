#!/bin/bash
#
# Convert realpath_turbo PECL package on PHP 7.x to a Debian package.
#
# VERSION       :3.0.0

set -e

wget -qO- https://packages.sury.org/php/apt.gpg | sudo -- apt-key add -
echo "deb https://packages.sury.org/php/ stretch main" | sudo -- tee /etc/apt/sources.list.d/sury-php.list
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 451A4FBA
echo "deb http://szepeviktor.github.io/debian/ stretch main" | sudo -- tee /etc/apt/sources.list.d/szepeviktor.list

sudo apt-get update
sudo apt-get install -qq dh-make-php devscripts xsltproc php-dev

# Download master branch
wget -qO- https://github.com/Whissi/realpath_turbo/archive/master.tar.gz | tar -xz

# Make up a PECL archive
mv -v realpath_turbo-master realpath_turbo-2.0.0
mv -v realpath_turbo-2.0.0/package.xml .
# Debian allows no tabs
sed -i -e 's|\t|    |g' package.xml
tar -czf realpath-turbo.tgz realpath_turbo-2.0.0 package.xml
rm -rf realpath_turbo-2.0.0 package.xml

# Convert with dh-make
# 
dh-make-pecl --package-name "realpath-turbo" \
    --maintainer "Viktor Szepe <viktor@szepe.net>" \
    --depends "php-common (>= 1:61), phpapi-$(/usr/bin/php-config --phpapi)" \
    realpath-turbo.tgz

# Fix underscores in names
(
    cd php-realpath-turbo-2.0.0/
    sed -e 's|^PECL_PKG_NAME=realpath-turbo$|PECL_PKG_NAME=realpath_turbo|' \
        -e 's|PECL_PKG_NAME)\.ini|PECL_PKG_REALNAME).ini|' \
        -i debian/rules

    cat > debian/realpath-turbo.ini <<"EOF"
; configuration for realpath_turbo module
; priority=20
extension=realpath_turbo.so

; Disable dangerous functions (see the warning in the README file for
; details).
; Possible values:
;   0 - Ignore potential security issues
;   1 - Disable dangerous PHP functions (link,symlink)
realpath_turbo.disable_dangerous_functions = 1

; Set realpath_turbo.open_basedir to whatever you want to set open_basedir to
;realpath_turbo.open_basedir = "/home/user/website/code"

; Disable PHP's open_basedir directive so that the realpath cache won't be
; disabled.
; Remember, realpath_turbo will set this option later to the
; realpath_turbo.open_basedir value.
open_basedir = ""
EOF

    # Build the package
    dpkg-buildpackage -uc -us -B
)

echo "OK."
