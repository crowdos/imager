OUTPUT_EXTRA_PACKAGES=e2fsprogs

install_bootloader() {
    echo "====================="
    echo "Installing bootloader"
    echo "====================="

    mkdir -p $MNT_DIR/boot/extlinux
    cat > $MNT_DIR/script <<EOF
#!/bin/sh
set -x
mount -t proc proc proc
mount -t sysfs sys sys
/usr/bin/extlinux -i /boot/extlinux/
dd if=/usr/lib/EXTLINUX/mbr.bin of=/dev/loop0 bs=440 count=1 conv=notrunc
umount proc
umount sys
EOF
    chmod +x $MNT_DIR/script
    chroot $MNT_DIR /script
    rm -rf $MNT_DIR/script
}

prepare_output() {
    dd if=/dev/null of=$OUTPUT bs=2M seek=1024
    echo -e "n\np\n\n\n\na\nw\n" | /sbin/fdisk $OUTPUT
    /sbin/losetup /dev/loop0 $OUTPUT
    /sbin/kpartx -as /dev/loop0
    /sbin/mkfs.ext4 -F -L root /dev/mapper/loop0p1
    /sbin/tune2fs -c 0 -i 0 /dev/mapper/loop0p1
    MNT_DIR=$(mktemp -d)
    mount -t auto /dev/mapper/loop0p1 $MNT_DIR

    tar --numeric-owner -C $DIR -cp . | tar -C $MNT_DIR --numeric-owner -xf -

    install_bootloader

    umount $MNT_DIR

    /sbin/kpartx -ds /dev/loop0
    /sbin/losetup -d /dev/loop0

    rm -rf $MNT_DIR
}
