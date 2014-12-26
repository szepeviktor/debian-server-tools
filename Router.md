# ASUS-merlin firmware

### user name and password

non-root, non-admin

### WAN

(PPPoE) user/pass

### WiFi

SSID/WPA2-PSK AES

### Firmware

[check firmware version](https://www.mediafire.com/folder/bkfq2a6aebq68//Asuswrt-Merlin#yvgnw5wo8wrco)

### USB disk

enable scheduled disk scan

### LAN

router LAN IP 192.168.12.1
LAN IP range 129.168.12.129 - 129.168.12.190

### NTP

NTP servers 0.hu.pool.ntp.org

### SSH

SSH key

### DDNS

egry.no-ip.com

### IPv6 tunnel

SixXS

- Native/PPP
- DNS 2001:4860:4860::8888 2001:4860:4860::8844

### Backup

```bash
#!/bin/sh

opkg update
opkg upgrade

# backup items: settings, jffs, root files, USB drive

USB_ROOT="/tmp/mnt/optware"

[ -d "${USB_ROOT}/backup/" ] || exit 1
cd "${USB_ROOT}/backup/"

nvram save "Setting_$(nvram get productid).CFG" || exit 1
echo -------------------------------

tar cf jffs-bck.tar /jffs/ || exit 1
echo -------------------------------

tar cf root-bck.tar ../root/ || exit 1
echo -------------------------------

# USB drive backup
echo "listen: nc -l -p 123 | gzip -9 > /opt/router-bck/router.tar.gz"
read
tar cv "$USB_ROOT" | nc szerver4. 123 || exit 1
echo -------------------------------

```
