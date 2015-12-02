OUTPUT_EXTRA_PACKAGES=e2fsprogs

install_bootloader() {
    echo "====================="
    echo "Installing bootloader"
    echo "====================="

    UUID=$(blkid -o value -s UUID  /dev/mapper/loop0p1)
    PARTUUID=$(blkid -o value -s PARTUUID  /dev/mapper/loop0p1)
    # We must use PARTUUID
    # http://unix.stackexchange.com/a/93777
    cat <<EOF >> $MNT_DIR/etc/grub.d/40_custom
menuentry "CrowdOS" {
        insmod part_msdos
        insmod ext2
        set root=(hd0,msdos1)
        search --no-floppy --fs-uuid --set=root $UUID
        linux /boot/vmlinuz ro quiet root=PARTUUID=$PARTUUID video=400x600 init=/sbin/runit-init
}
EOF
    cat > $MNT_DIR/script <<EOF
#!/bin/sh
set -x
sed -ie 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
grub-install /dev/loop0
update-grub
EOF
    for i in dev proc sys; do
	mount --bind /$i $MNT_DIR/$i
    done

    chmod +x $MNT_DIR/script
    chroot $MNT_DIR /script
    rm -rf $MNT_DIR/script

    for i in dev proc sys; do
	umount $MNT_DIR/$i
    done
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
