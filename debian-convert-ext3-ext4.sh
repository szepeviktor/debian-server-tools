#!/bin/bash
#
# Convert root filesystem to ext4 during boot.
#

# Check current filesystem type
ROOT_FS_TYPE="$(sed -n -e 's|^/dev/[a-z]\+[1-9]\+ / \(ext3\) .*$|\1|p' /proc/mounts)"
test "$ROOT_FS_TYPE" == ext3 || exit 100

# Copy tune2fs to initrd
cat > /etc/initramfs-tools/hooks/tune2fs <<"EOF"
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
copy_exec /sbin/tune2fs /sbin
EOF
chmod +x /etc/initramfs-tools/hooks/tune2fs

# Execute tune2fs before mounting root filesystem
cat > /etc/initramfs-tools/scripts/init-premount/ext4 <<"EOF"
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

/sbin/tune2fs -O extents,uninit_bg,dir_index -f "$ROOT" || echo "tune2fs: $?"
EOF
chmod +x /etc/initramfs-tools/scripts/init-premount/ext4

# Change specified filesystem
sed -i -e 's|\sext3\s| ext4 |' /etc/fstab

# Regenerate initrd
update-initramfs -v -u

# Remove files
rm -f /etc/initramfs-tools/hooks/tune2fs /etc/initramfs-tools/scripts/init-premount/ext4

reboot

# Remove files from initrd after reboot
# update-initramfs -u
