#!/bin/bash

set -e

if [ "$(id -u)" != "0" ]; then
    echo "Script must be run as root"
    exit 0
fi

if [ $# -ne 2 ]; then
    echo "Usage $0 <output file> <build profile>"
    exit 1
fi

OUTPUT=$1
PROFILE=$2

. $PROFILE
. output/$OUTPUT_TYPE.sh

# TODO: remove dhcpcd5 later
EXTRA_PACKAGES="$OUTPUT_EXTRA_PACKAGES crowdos-base net-tools wget dhcpcd5"
APT_OPTS="-y --no-install-recommends --no-install-suggests --force-yes"

HOST_ARCH=$(uname -m)

if [ "$HOST_ARCH" != "$ARCH" ]; then
    DEBOOTSTRAP=qemu-debootstrap
else
    DEBOOTSTRAP=debootstrap
fi

function cleanup() {
    mountpoint -q $DIR/dev && umount $DIR/dev
    if [ -f $DIR/debootstrap/debootstrap.log ]; then
	cat $DIR/debootstrap/debootstrap.log
    fi

    rm -rf $DIR
}

trap cleanup SIGINT EXIT

CACHE_TARBALL=$DEBIAN_SUITE-$ARCH.tgz

DIR=$(mktemp -d)

if [ ! -f $CACHE_TARBALL ]; then
    echo "Generating debootstrap cache tarball"
    $DEBOOTSTRAP --variant=minbase --arch=$ARCH --make-tarball=$CACHE_TARBALL $DEBIAN_SUITE $DIR
    DIR=$(mktemp -d)
fi

echo "========================="
echo "Build directory: $DIR"
echo "========================="

$DEBOOTSTRAP --variant=minbase --arch=$ARCH --unpack-tarball=`pwd`/$CACHE_TARBALL $DEBIAN_SUITE $DIR
echo "LABEL=root / auto defaults 0 1" >> $DIR/etc/fstab
echo "proc /proc proc defaults 0 0" >> $DIR/etc/fstab
echo "sysfs /sys sysfs defaults 0 0" >> $DIR/etc/fstab
echo "deb http://security.debian.org jessie/updates main" >> $DIR/etc/apt/sources.list
echo "deb http://crowdos.foolab.org scratch main $EXTRA_REPO_COMPONENT" >> $DIR/etc/apt/sources.list

mount --bind /dev/ $DIR/dev/

chroot $DIR apt-get update
chroot $DIR apt-get install $APT_OPTS eatmydata

# init is essential so we must force it.
chroot $DIR dpkg --force-all -P init

chroot $DIR eatmydata apt-get install $APT_OPTS $EXTRA_PACKAGES

chroot $DIR apt-get clean
chroot $DIR apt-get --purge -y remove eatmydata libeatmydata1 systemd systemd-sysv

rm -rf $DIR/etc/systemd

prepare_output

trap - SIGINT EXIT

cleanup

echo "Image created: $OUTPUT"
