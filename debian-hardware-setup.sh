
dmidecode --string 2>&1|grep "^ "|xargs -I "%" sh -c 'echo -n "%="; dmidecode --string %;'
lspci
lsusb

smatmontools + alert
sensors volt, fan, ... + alert
ntpdate + hwclock --systohc
ups + alert
router watch + alert
