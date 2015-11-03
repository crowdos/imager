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
    umount $DIR
    /sbin/kpartx -ds /dev/loop0
    /sbin/losetup -d /dev/loop0
    rm -rf $DIR
}

install_bootloader() {
    echo "====================="
    echo "Installing bootloader"
    echo "====================="

    chroot $DIR eatmydata apt-get install $APT_OPTS $BOOTLOADER

    mkdir -p $DIR/boot/extlinux
    cat > $DIR/script <<EOF
#!/bin/sh
mount -t proc proc proc
mount -t sysfs sys sys
/usr/bin/extlinux -i /boot/extlinux/
umount proc
umount sys
EOF
    chmod +x $DIR/script
    chroot $DIR /script
    rm -rf $DIR/script
    cat > $DIR/boot/extlinux/extlinux.conf <<EOF
default CrowdOS
label CrowdOS
      menu label CrowdOS
      kernel /vmlinuz
      append initrd=/initrd.img root=/dev/sda1 ro quiet video=400x600
EOF
}
