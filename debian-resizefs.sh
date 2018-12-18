#!/bin/bash
#
# Resize root filesystem during boot.
#
# VERSION       :1.0.1
# DATE          :2018-04-01
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# ALTERNATIVE   :http://www.ivarch.com/blogs/oss/2007/01/resize-a-live-root-fs-a-howto.shtml

# Check current filesystem type
ROOT_FS_TYPE="$(sed -n -e 's|^/dev/\S\+ / \(ext4\) .*$|\1|p' /proc/mounts)"
test "$ROOT_FS_TYPE" == ext4 || exit 100

# Copy e2fsck and resize2fs to initrd
cat > /etc/initramfs-tools/hooks/resize2fs <<"EOF"
#!/bin/sh

PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

. /usr/share/initramfs-tools/hook-functions
copy_exec /sbin/findfs /sbin
copy_exec /sbin/e2fsck /sbin
copy_exec /sbin/resize2fs /sbin
EOF

chmod +x /etc/initramfs-tools/hooks/resize2fs

# Execute resize2fs before mounting root filesystem
cat > /etc/initramfs-tools/scripts/init-premount/resize <<"EOF"
#!/bin/sh

PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

# New size of root filesystem
ROOT_SIZE="8G"

# Convert root from possible UUID to device name
echo "root=${ROOT}  "
ROOT_DEVICE="$(/sbin/findfs "$ROOT")"
echo "root device name is ${ROOT_DEVICE}  "
# Make sure LVM volumes are activated
if [ -x /sbin/vgchange ]; then
    /sbin/vgchange -a y || echo "vgchange: $?  "
fi
# Check root filesystem
/sbin/e2fsck -y -v -f "$ROOT_DEVICE" || echo "e2fsck: $?  "
# Resize
# debug-flag 8 means debug moving the inode table
/sbin/resize2fs -d 8 "$ROOT_DEVICE" "$ROOT_SIZE" || echo "resize2fs: $?  "
EOF

chmod +x /etc/initramfs-tools/scripts/init-premount/resize

# Regenerate initrd
update-initramfs -v -u

# Remove files
rm -f /etc/initramfs-tools/hooks/resize2fs /etc/initramfs-tools/scripts/init-premount/resize

reboot

# List files in initrd
# lsinitramfs /boot/initrd.img-*-amd64

# Remove files from initrd after reboot
# update-initramfs -u
