#!/bin/bash

exit 0

amd64-microcode
intel-microcode

apt-get install -y smartmontools

dmidecode
dmidecode --string 2>&1|grep "^\s"|xargs -I %% bash -c 'echo "%%=$(dmidecode --string %%)"'
lspci
lsusb
#sensors, IPMI

# chrony
editor /etc/default/hwclock

editor /etc/default/smartmontools
editor /etc/smartd.conf

# Display HDD temperature on login
# See /input/update-motd.d/10-sysinfo

# Entropy from TPM
modprobe tpm-rng
echo tpm-rng >> /etc/modules

# monit
# - smartmontools
# - xenstored, xenconsoled
/usr/lib/xen-4.4/bin/xenstored --pid-file=/var/run/xenstore.pid
/usr/lib/xen-4.4/bin/xenconsoled --pid-file=/var/run/xenconsoled.pid
# - mdadm
grep "^ARRAY" /etc/mdadm/mdadm.conf|cut -d' ' -f2

cat <<EOF > /etc/monit/monitrc.d/mdadm-fs
check filesystem dev_md0 with path /dev/md/0
  group mdadm
  if space usage > 80% for 5 times within 15 cycles then alert
EOF

apt-get install -y ipmitool
# Munin/ipmitool
# Munin/sensors
# Munin/ups
# Munin/router ping IP

apt-get install linux-cpupower

# CPU frequency scaling governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# Set performance mode
for SG in /sys/devices/system/cpu/*/cpufreq/scaling_governor;do echo "performance" > $SG;done

# Firmware
if [ -d /dev/.udev/firmware-missing ] || [ -d /run/udev/firmware-missing ]; then
    echo "Probably missing firmware" 1>&2
    exit 1
fi
