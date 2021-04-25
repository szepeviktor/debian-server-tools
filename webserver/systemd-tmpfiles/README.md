# Dummy package with 1 symlink

Later versions of Ondřej Surý's PHP-FPM packages
[depend on `systemd`](https://github.com/oerdnj/deb.sury.org/issues/1347).

`systemd-tmpfiles` provides one symlink to the `opentmpfiles` command.

### Building

1. Install [equivs version 2.1+](https://packages.debian.org/buster/equivs)
1. Build the dummy package: `equivs-build systemd-tmpfiles`

### Installation

1. Install [opentmpfiles](https://packages.debian.org/sid/opentmpfiles)
1. Install the dummy package: `dpkg -i ./systemd-tmpfiles_*_amd64.deb`
