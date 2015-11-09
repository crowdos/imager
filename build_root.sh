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

# TODO: remove dhcpcd5 later
EXTRA_PACKAGES="$OUTPUT_EXTRA_PACKAGES crowdos-base net-tools wget dhcpcd5"
APT_OPTS="-y --no-install-recommends --no-install-suggests"
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

function _cleanup() {
    mountpoint $DIR/dev && umount $DIR/dev
    cleanup
}

trap _cleanup SIGINT EXIT

create_temp_dir

echo $DIR

echo "========================="
echo "Build directory: $DIR"
echo "========================="

$DEBOOTSTRAP --variant=minbase --arch=$ARCH $DEBIAN_SUITE $DIR
echo "proc /proc proc defaults 0 0" >> $DIR/etc/fstab
echo "LABEL=root / auto defaults 0 1" >> $DIR/etc/fstab
echo "deb http://security.debian.org jessie/updates main" >> $DIR/etc/apt/sources.list

mount --bind /dev/ $DIR/dev/

chroot $DIR apt-get update
chroot $DIR apt-get install $APT_OPTS eatmydata
chroot $DIR eatmydata apt-get install $APT_OPTS $EXTRA_PACKAGES

install_bootloader

chroot $DIR apt-get clean
chroot $DIR apt-get --purge -y remove eatmydata libeatmydata1 systemd systemd-sysv

#chroot $DIR apt-get update

rm -rf $DIR/etc/systemd

_cleanup

echo "Image created: $IMG"

trap - SIGINT EXIT
