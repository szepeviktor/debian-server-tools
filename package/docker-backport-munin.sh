#!/bin/bash
#
# Build munin from Debian pristine-tar branch.
#
# DEPENDS       :docker pull szepeviktor/jessie-backport:0.2.1

# Usage
#
# EDIT: pristine-tar latest, munin release version, docker image

[ -d /opt/results ] || mkdir /opt/results

# init hook ----------
cat <<"EOF" > /opt/results/debackport-init
set -x
EOF


# source hook ----------
cat <<"EOF" > /opt/results/debackport-source
sudo apt-get install -y git pristine-tar

git clone https://anonscm.debian.org/git/collab-maint/munin.git
cd munin/

git checkout pristine-tar
pristine-tar list | tail -n 1
# EDIT munin version
pristine-tar checkout ../munin_2.999.2.orig.tar.gz
# "Packagers can use that (2.999.x) versionning or 3.0b2"
# EDIT versions
mv -v ../munin_2.999.2.orig.tar.gz ../munin_3.0b2.orig.tar.gz

git checkout debian-experimental

CHANGELOG_MSG="From Debian git/debian-experimental"
EOF


# pre-deps hook ----------
cat <<"EOF" > /opt/results/debackport-pre-deps
# HTTP::Server::Simple::CGI
sudo apt-get install -y libhttp-server-simple-perl

# Alien::RRDtool
sudo apt-get install -y pkg-config graphviz libxml2-dev libpango1.0-dev libcairo2-dev \
    libfile-sharedir-perl libtest-requires-perl
sudo PERL_MM_USE_DEFAULT=1 cpan -i Alien::RRDtool
EOF


# changes hook ----------
cat <<"EOF" > /opt/results/debackport-changes
dch --newversion "3.0b2-1~bpo8+1" --distribution "${CURRENT_RELEASE}-backports" "$CHANGELOG_MSG"
EOF


# post-build hook ----------
cat <<"EOF" > /opt/results/debackport-post-build
ls -l ../*.deb
EOF


# Build it ----------
# EDIT jessie-backport version
docker run --rm --tty -v /opt/results:/opt/results --env PACKAGE="munin" szepeviktor/jessie-backport:0.2.1
rm -f /opt/results/{debackport-init,debackport-source,debackport-pre-deps,debackport-changes,debackport-post-build}
