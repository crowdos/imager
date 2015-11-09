OUTPUT_EXTRA_PACKAGES=e2fsprogs

create_temp_dir() {
    dd if=/dev/null of=$IMG bs=2M seek=1024
    echo -e "n\np\n\n\n\na\nw\n" | /sbin/fdisk $IMG
    /sbin/losetup /dev/loop0 $IMG
    /sbin/kpartx -as /dev/loop0
    /sbin/mkfs.ext4 -F -L root /dev/mapper/loop0p1
    /sbin/tune2fs -c 0 -i 0 /dev/mapper/loop0p1
    DIR=$(mktemp -d)
    mount -t auto /dev/mapper/loop0p1 $DIR
}

cleanup() {
    mount | grep -q $DIR || return
    mountpoint $DIR && umount $DIR
    /sbin/kpartx -ds /dev/loop0
    /sbin/losetup -d /dev/loop0
    rm -rf $DIR
}

install_bootloader() {
    echo "====================="
    echo "Installing bootloader"
    echo "====================="

    mkdir -p $DIR/boot/extlinux
    cat > $DIR/script <<EOF
#!/bin/sh
set -x
mount -t proc proc proc
mount -t sysfs sys sys
/usr/bin/extlinux -i /boot/extlinux/
dd if=/usr/lib/EXTLINUX/mbr.bin of=/dev/loop0 bs=440 count=1 conv=notrunc
umount proc
umount sys
EOF
    chmod +x $DIR/script
    chroot $DIR /script
    rm -rf $DIR/script
}
