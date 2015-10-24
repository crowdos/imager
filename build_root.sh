#!/bin/bash

set -e

if [ "$(id -u)" != "0" ]; then
    echo "Script must be run as root"
    exit 0
fi

if [ $# -ne 2 ]; then
echo "Usage $0 <Image file> <build profile>"
exit 1
fi

IMG=$1
PROFILE=$2

. $PROFILE
. output/$OUTPUT_TYPE.sh

EXTRA_PACKAGES="netbase net-tools wget"

DEBOOTSTRAP=debootstrap
case `uname -m` in
    i686|i586)
	if [ "$ARCH" == "arm" ]; then
	    DEBOOTSTRAP=qemu-debootstrap
	fi
	;;
    armv7l)
	;;
    *)
	echo "Unknown architecture"
	exit 1
	;;
esac

create_temp_dir

echo $DIR

echo "========================="
echo "Build directory: $DIR"
echo "========================="

$DEBOOTSTRAP --variant=minbase --include=sysvinit-core --arch=$ARCH $DEBIAN_SUITE $DIR
echo "proc /proc proc defaults 0 0" >> $DIR/etc/fstab
echo "sysfs /sys sysfs defaults 0 0" >> $DIR/etc/fstab
echo "deb http://security.debian.org jessie/updates main" >> $DIR/etc/apt/sources.list
chroot $DIR apt-get update
chroot $DIR dpkg -P systemd systemd-sysv
#chroot $DIR apt-get install -y $EXTRA_PACKAGES
#chroot $DIR apt-get update

rm -rf $DIR/etc/systemd

create_output

echo "Image created: $IMG"
