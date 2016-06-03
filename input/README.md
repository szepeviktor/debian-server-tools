### pam_motd

```bash
[ -d /etc/update-motd.d ] || mkdir /etc/update-motd.d
ln -svf /var/run/motd /etc/motd
#echo -e "*\n*** This server is the property of <COMPANY-NAME> Unauthorized entry is prohibited. ***\n*\n" > /etc/motd.tail
echo -e "*\n*** Ez a szerver <a/az CÉG-NÉV> tulajdona. Idegeneknek a belépés tilos. ***\n*\n" > /etc/motd.tail
cp -avf ./motd_user.sh /etc/profile.d/
cp -avf ./update-motd.d /etc/
```

### "Rainbows and unicorns!"

`pip3 install lolcat`

