#!/bin/bash
#
# Add new Apache site.
#

set -e

read -r -e -p "user name: " U
read -r -e -p "domain name without WWW: " DOMAIN

# Create system user
adduser --disabled-password --gecos "" "$U"

# Check DNS record
host -t A "$DOMAIN"

# Add webserver to this group
adduser _web "$U"

# Website directories
mkdir -v --mode=0750 "/home/${U}/website"
mkdir -v "/home/${U}/website/"{session,tmp,code,pagespeed,backup}
chmod 0555 "/home/${U}/website/code"
# Add hosting.yml
cp -v /usr/local/src/debian-server-tools/webserver/hosting.yml "/home/${U}/website/"
# Create empty wp-cli.yml
touch "/home/${U}/website/wp-cli.yml"

# Set owner
chown -c -R "${U}:${U}" "/home/${U}/"

# PHP pool
cd /etc/php/7.2/fpm/pool.d/
sed -e "s/@@USER@@/${U}/g" <../Skeleton-pool.conf >"${U}.conf"

# Apache vhost
cd /etc/apache2/sites-available/
# SSL
sed -e "s/@@SITE_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" <Skeleton-site-ssl.conf >"${DOMAIN}.conf"

# Enable site
a2ensite "$DOMAIN"
apache-resolve-hostnames.sh

cat <<"EOF"
Steps to follow for a complete website
--------------------------------------
- Install and set up CLI script for DNS
- Create DNS records
- Install manuale
- Issue and install SSL certificate
- Create database and user
- Import database
- Deploy code base
- Add root files
- Set up mail sending
EOF
