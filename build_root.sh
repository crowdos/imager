#!/bin/bash

if [ $# -ne 1 ]; then
echo "Image file needed"
exit 1
fi

IMG=$1

dd if=/dev/null of=$IMG bs=2M seek=1024
echo -e "n\np\n\n\n\nw\n" | /sbin/fdisk $IMG
/sbin/mkfs.ext4 -L root -F $IMG
/sbin/tune2fs -c 0 -i 0 $IMG

DIR=$(mktemp -d)

echo "========================="
echo "Mount directory: $DIR"
echo "========================="

mount -t auto $IMG $DIR -oloop

debootstrap --variant=minbase --include=sysvinit-core jessie $DIR
echo "proc /proc proc defaults 0 0" >> $DIR/etc/fstab
echo "sysfs /sys sysfs defaults 0 0" >> $DIR/etc/fstab
echo "deb http://security.debian.org jessie/updates main" >> $DIR/etc/apt/sources.list
chroot $DIR apt-get update
chroot $DIR dpkg -P systemd systemd-sysv
chroot $DIR apt-get install netbase net-tools wget
chroot $DIR apt-get update

rm -rf $DIR/etc/systemd
umount $DIR
rm -rf $DIR

echo "Image created"
