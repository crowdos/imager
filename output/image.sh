create_temp_dir() {
    dd if=/dev/null of=$IMG bs=2M seek=1024
    echo -e "n\np\n\n\n\nw\n" | /sbin/fdisk $IMG
    /sbin/mkfs.ext4 -L root -F $IMG
    /sbin/tune2fs -c 0 -i 0 $IMG
    DIR=$(mktemp -d)
    mount -t auto $IMG $DIR -oloop
}

create_output() {
    umount $DIR
    rm -rf $DIR
}
