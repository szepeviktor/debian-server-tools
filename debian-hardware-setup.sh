exit 0

dmidecode --string 2>&1|grep "^ "|xargs -I "%" sh -c 'echo "%=$(dmidecode --string %)"'
lspci
lsusb

ntpdate + hwclock --systohc

smatmontools + alert
?hddtemp

sensors volt, fan, ... + alert

ipmitool + alert

ups + alert

router watch + alert

bash_rc: /monitoring/hdd-temps.sh