#!/bin/bash

NGXC="/etc/nginx"

set -e -x

. debian-setup-functions.inc.sh

# Nginx 1.8
apt-get install -y nginx-lite
# Nginx packages: lite, full, extra
#    https://docs.google.com/a/moolfreet.com/spreadsheet/ccc?key=0AjuNPnOoex7SdG5fUkhfc3BCSjJQbVVrQTg4UGU2YVE#gid=0
#    apt-get install -y nginx-full

# Put ngx-conf in PATH
ln -sf /usr/sbin/ngx-conf/ngx-conf /usr/local/sbin/ngx-conf

# HTTP/AUTH
mkdir /etc/nginx/http-auth
# Configuration
#    https://codex.wordpress.org/Nginx
#    http://wiki.nginx.org/WordPress
git clone https://github.com/szepeviktor/server-configs-nginx.git

cp -a h5bp/ ${NGXC}
cp -f mime.types ${NGXC}
cp -f nginx.conf ${NGXC}
ngx-conf --disable default
cp -f sites-available/no-default ${NGXC}/sites-available
ngx-conf --enable no-default
