#!/bin/bash

set -x
set -u
set -e

if [[ ! -z "${PACMAN_CACHE:-}" ]]; then
  sed -i "1i Server = ${PACMAN_CACHE}" /etc/pacman.d/mirrorlist
fi

## Disk
DISK='/dev/sda'
BIOS_PARTITION="${DISK}1"
ROOT_PARTITION="${DISK}2"
/usr/bin/sgdisk --zap-all ${DISK}
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}
sgdisk -og "${DISK}"
ENDSECTOR="$(sgdisk -E ${DISK})"
sgdisk -n 1:2048:4095 -c 1:"biosboot" -t 1:ef02 ${DISK}
sgdisk -n 2:4096:${ENDSECTOR} -c 2:"root" -t 2:8300 ${DISK}
sgdisk -p ${DISK}
mkdir -p /mnt/boot
/usr/bin/mkfs.vfat -n biosboot ${BIOS_PARTITION}
/usr/bin/mkfs.ext4 -F -m 0 -q -L root ${ROOT_PARTITION}
/usr/bin/mount -o noatime,errors=remount-ro ${ROOT_PARTITION} /mnt

## Bootstrap
pacman -Syy
pacstrap /mnt base base-devel

## Fstab
genfstab -p /mnt > /mnt/etc/fstab

cat "configure.sh" | arch-chroot /mnt bash -

sed -i "1d" /mnt/etc/pacman.d/mirrorlist

sync
umount "${ROOT_PARTITION}"
sync
