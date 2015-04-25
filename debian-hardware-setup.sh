exit 0

dmidecode --string 2>&1|grep "^ "|xargs -I "%" sh -c 'echo -n "%="; dmidecode --string %;'
lspci
lsusb

ntpdate + hwclock --systohc
smatmontools + alert
sensors volt, fan, ... + alert
ipmitool + alert
ups + alert
router watch + alert
