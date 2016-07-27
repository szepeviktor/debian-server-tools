#
# Display monit erroneous status.
#
# DEPENDS       :apt-get install monit
# LOCATION      :/etc/profile.d/monit_status.sh

if [ "$(id -u)" == 0 ] && which monit &> /dev/null; then
    IGNORED_STATUSES="Running|Accessible|Status ok|Waiting"
    if /usr/bin/monit -B summary | tail -n +3 \
        | grep -vE "\sSystem\s*\$|\s(${IGNORED_STATUSES})\s*\S+\s*\$"; then
        echo
        echo "[ALERT] Monit status is NOT OK."
    fi
fi
