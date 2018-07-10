#
# Alert when reboot is required.
#
# DOCS          :https://github.com/liske/needrestart/blob/master/perl/lib/NeedRestart/Kernel.pm#L33
# DEPENDS       :apt-get install needrestart
# LOCATION      :/etc/profile.d/reboot_required.sh
# OWNER         :root:root
# PERMISSION    :0644

if [[ $EUID -eq 0 ]] && [ -x /usr/sbin/needrestart ]; then
    NEEDRESTART="$(/usr/sbin/needrestart -b -k | grep -x 'NEEDRESTART-KSTA: [0-9]')"
    NEEDRESTART="${NEEDRESTART#*: }"
    if [ "$NEEDRESTART" != 0 ] && [ "$NEEDRESTART" != 1 ]; then
        echo
        echo "[ALERT] Reboot required."
    fi
    unset NEEDRESTART
fi
