#!/bin/bash
#
# DOCS          :dpkg -L cowsay|grep /usr/share/cowsay/cows/|xargs -I %% /usr/games/cowsay -f %% %%|pager
# DEPENDS       :apt-get install cowsay
# LOCATION      :/etc/profile.d/motd_user.sh

[ -f "${HOME}/.motd" ] || exit 0

/usr/games/cowsay -f apt < "${HOME}/.motd"
