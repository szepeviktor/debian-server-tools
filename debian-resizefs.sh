#!/bin/bash
#
# Resize root filesystem during boot.
#
# Alternative: http://www.ivarch.com/blogs/oss/2007/01/resize-a-live-root-fs-a-howto.shtml

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

# Size resize root fs to
ROOT_SIZE="8G"

wait-for-root "${ROOT}" 20
/sbin/e2fsck -y -f "${ROOT}" || echo "e2fsck: $?"
/sbin/resize2fs -d 8 "${ROOT}" "${ROOT_SIZE}" || echo "resize2fs: $?"
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
