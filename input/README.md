### pam_motd

```bash
apt-get install -y figlet bc cowsay
[ -d /etc/update-motd.d ] || mkdir -v /etc/update-motd.d
mv -v /etc/motd /etc/motd~
ln -svf /var/run/motd /etc/motd
echo -e "*\n*** Ez a szerver <a/az CÉG-NÉV> tulajdona. Idegeneknek a belépés tilos. ***\n*\n" > /etc/motd.tail
#echo -e "*\n*** This server is the property of <COMPANY-NAME>. Unauthorized entry is prohibited. ***\n*\n" > /etc/motd.tail
cp -avf ./update-motd.d /etc/
cp -avf ./profile.d /etc/
echo "4" > /etc/hostcolor
```

### "Rainbows and unicorns!"

`pip3 install lolcat`

### Send broadcast message to all users

`wall "MSG"`

To root-s only: `logger -p user.error "MSG"`
