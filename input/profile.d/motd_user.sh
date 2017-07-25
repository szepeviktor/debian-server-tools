#
# Display user motd.
#
# LOCATION      :/etc/profile.d/motd_user.sh
# OWNER         :root:root
# PERMISSION    :0644

if [ -f "${HOME}/.motd" ]; then
    echo -n "*** "
    cat "${HOME}/.motd"
fi
