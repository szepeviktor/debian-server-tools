#
# Display monit erroneous status.
#
# DEPENDS       :apt-get install monit
# LOCATION      :/etc/profile.d/monit_status.sh
# OWNER         :root:root
# PERMISSION    :0644

if [[ $EUID -eq 0 ]] && [ -x /usr/bin/monit ]; then
    IGNORED_STATUSES="Running|Accessible|OK|Online with all services|Waiting"
    # Convert to tabular output
    if /usr/bin/monit -B summary \
        | tail -n +3 | sed -e 's|^ ||' -e 's|\s\s\+|\t|g' \
        | grep -vE "	(${IGNORED_STATUSES})	"; then

        echo
        echo "[ALERT] Monit status is NOT OK."
    fi
    unset IGNORED_STATUSES
fi
