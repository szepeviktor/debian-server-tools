#
# Display monit erroneous status.
#
# DEPENDS       :apt-get install monit
# LOCATION      :/etc/profile.d/monit_status.sh
# OWNER         :root:root
# PERMISSION    :0644

if [ "$(id -u)" == 0 ] && which monit &> /dev/null; then
    TAB=$'\t'
    IGNORED_STATUSES="Running|Accessible|Status ok|Online with all services|Waiting"
    if /usr/bin/monit -B summary \
        | tail -n +3 | sed -e 's|^ ||' -e 's|\s\s\+|\t|g' \
        | grep -Ev "${TAB}(${IGNORED_STATUSES})${TAB}"; then

        echo
        echo "[ALERT] Monit status is NOT OK."
    fi
fi
