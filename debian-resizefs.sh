#!/bin/bash
#
# Resize root filesystem during boot.
#

# Check current filesystem type
ROOT_FS_TYPE="$(sed -n -e 's|^/dev/[a-z]\+[1-9]\+ / \(ext4\) .*$|\1|p' /proc/mounts)"
test "$ROOT_FS_TYPE" == ext4 || exit 100

# Copy resize2fs to initrd
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

/sbin/e2fsck -f "$ROOT" || echo "e2fsck: $?"
# Size in filesystem blocks, usually 4 KB
# tune2fs -l /dev/vda1
# 1310720 blocks = 5 GB
/sbin/resize2fs -d 8 "$ROOT" 1310720 || echo "resize2fs: $?"
EOF
chmod +x /etc/initramfs-tools/scripts/init-premount/resize

# Regenerate initrd
update-initramfs -v -u

# Remove files
rm -f /etc/initramfs-tools/hooks/resize2fs /etc/initramfs-tools/scripts/init-premount/resize

reboot

# Remove files from initrd after reboot
# update-initramfs -u
