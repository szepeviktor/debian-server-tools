#
# Display monit erroneous status.
#
# DEPENDS       :apt-get install monit
# LOCATION      :/etc/profile.d/monit_status.sh

if [ "$(id -u)" == 0 ] && which monit &> /dev/null; then
    if monit summary | grep -vE "\s(Running|Accessible|Status ok|Waiting)\$|^The Monit daemon |^\$"; then
        echo
        echo "[ALERT] Monit status is NOT OK."
    fi
fi
