echo 'Dpkg::Use-Pty "0";' > /etc/apt/apt.conf.d/00usepty

[ -d /tmp ] && cd /tmp/

wget -nv -O- https://github.com/szepeviktor/debian-server-tools/archive/master.tar.gz|tar xz
cd debian-server-tools-master/
# Will error out at debian-setup/hostname
./debian-setup.sh

rm -f /etc/apt/apt.conf.d/00usepty

echo "OK."
