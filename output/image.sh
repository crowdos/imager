create_temp_dir() {
    dd if=/dev/null of=$IMG bs=2M seek=1024
    echo -e "n\np\n\n\n\na\nw\n" | /sbin/fdisk $IMG
    /sbin/losetup /dev/loop0 $IMG
    /sbin/kpartx -as /dev/loop0
    /sbin/mkfs.ext4 -F -L root /dev/mapper/loop0p1
    /sbin/tune2fs -c 0 -i 0 /dev/mapper/loop0p1
    DIR=$(mktemp -d)
    mount -t auto /dev/mapper/loop0p1 $DIR -oloop
}

cleanup() {
    mount | grep -q $DIR || return
    umount $DIR
    /sbin/kpartx -d /dev/loop0
    /sbin/losetup -d /dev/loop0
    rm -rf $DIR
}

create_output() {
    cleanup
}
