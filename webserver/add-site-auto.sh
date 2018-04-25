#!/bin/bash
#
# Add new Apache site.
#

set -e

read -r -e -p "user name: " U
read -r -e -p "domain name without WWW: " DOMAIN

# Create system user
adduser --disabled-password --gecos "" ${U}

# Check DNS record
host -t A ${DOMAIN}

# Add webserver to this group
adduser _web ${U}

# Website directories
mkdir -v --mode=0750 /home/${U}/website
mkdir -v /home/${U}/website/{session,tmp,html,pagespeed,backup}
chmod 0555 /home/${U}/website/html
# Create empty wp-cli.yml
touch /home/${U}/website/wp-cli.yml

# Set owner
chown -cR ${U}:${U} /home/${U}/

# PHP pool
cd /etc/php/7.2/fpm/pool.d/
sed "s/@@USER@@/${U}/g" < ../Skeleton-pool.conf > ${U}.conf

# Apache vhost
cd /etc/apache2/sites-available/
# Non-SSL
sed -e "s/@@SITE_DOMAIN@@/${DOMAIN}/g" -e "s/@@SITE_USER@@/${U}/g" < Skeleton-site.conf > ${DOMAIN}.conf

# Enable site
a2ensite ${DOMAIN}
apache-resolve-hostnames.sh
