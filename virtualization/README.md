# Automation of debian-setup.sh

### Configuration files management

- https://github.com/hercules-team/augeas/wiki/Path-expressions
- https://docs.saltstack.com/en/latest/ref/states/all/salt.states.file.html
- https://docs.ansible.com/ansible/list_of_files_modules.html
- https://puppetlabs.com/blog/why-puppet-isnt-a-file-management-tool

Use `conf.d` style configurations!

#### Configuration file patches

- by pkg
- by installed-version
- by config file

`diff -wu installed.conf new.conf`

### Kata Containers

Kata Containers is an open source project that brings the security
of hardware virtualization to containers through lightweight VMs.

https://www.youtube.com/watch?v=4gmLXyMeYWI

### Zeit Now

Realtime Global Deployments for Docker, Node.js, Static Websites https://zeit.co/now

### Manual backporting

```bash
# read -r DSC
# docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="$DSC" -i --entrypoint=/bin/bash szepeviktor/stretch-backport

sudo apt-get install -y nano
export DEBEMAIL="Viktor Szépe <viktor@szepe.net>"
dget -ux $PACKAGE
cd *
dpkg-buildpackage -us -uc
sudo apt-get install -y
dch --bpo --distribution "stretch-backports" "Built from buster"
nano debian/control
nano debian/rules
dpkg-buildpackage -us -uc
lintian --display-info --display-experimental --pedantic --show-overrides ../*.deb
sudo cp -v ../*.deb /opt/results/
```
