exit 0

apt-get install -y smartmontools

dmidecode --string 2>&1|grep "^ "|xargs -I "%" sh -c 'echo "%=$(dmidecode --string %)"'
lspci
lsusb

./install.sh monitoring/ntpdated
editor /etc/default/hwclock

editor /etc/default/smartmontools
editor /etc/smartd.conf

cat ${D}/monitoring/hdd-temps.sh >> /root/.bashrc

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
