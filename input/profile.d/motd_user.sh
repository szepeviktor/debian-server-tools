#
# Display user motd by cowsay.
#
# DOCS          :dpkg -L cowsay|grep /usr/share/cowsay/cows/|xargs -I %% /usr/games/cowsay -f %% %%|pager
# DEPENDS       :apt-get install cowsay
# LOCATION      :/etc/profile.d/motd_user.sh
# OWNER         :root:root
# PERMISSION    :0644

[ -f "${HOME}/.motd" ] && [ -x /usr/games/cowsay ] && /usr/games/cowsay -f apt < "${HOME}/.motd"
