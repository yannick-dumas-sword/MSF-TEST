#!/bin/bash

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <path-to-iso> <path-to-user-data> <path-to-meta-data>"
    exit 1
fi

ISO="$1"
USER_DATA="$2"
META_DATA="$3"

if [[ ! -f $ISO ]] || [[ ! -f $USER_DATA ]] || [[ ! -f $META_DATA ]]; then
    echo "Error: One or more files do not exist"
    exit 1
fi

echo "Creating a working copy of the ISO..."
mkdir -p /tmp/iso /tmp/iso_new
sudo mount -o loop "$ISO" /tmp/iso
rsync -a /tmp/iso/ /tmp/iso_new
sudo umount /tmp/iso
rmdir /tmp/iso

echo "Adding autoinstall files to the working copy..."
mkdir -p /tmp/iso_new/nocloud
cp "$USER_DATA" /tmp/iso_new/nocloud/user-data
cp "$META_DATA" /tmp/iso_new/nocloud/meta-data

echo "Adding the grub configuration file..."
mkdir -p /tmp/iso_new/boot/grub
cat << EOF > /tmp/iso_new/boot/grub/grub.cfg
set timeout=10
menuentry "Autoinstall Ubuntu Server" {
    set gfxpayload=keep
    linux   /casper/vmlinuz quiet autoinstall ip=dhcp ds=nocloud\;s=/cdrom/nocloud/  ---
##    linux   /casper/vmlinuz quiet autoinstall ds='nocloud-net;s=http://192.168.1.175:3003/'  ---

    initrd  /casper/initrd
}
EOF

echo "Creating the new ISO..."
sudo grub-mkrescue -o ./autoinstall.iso /tmp/iso_new
echo "Done. The new ISO is located at ./autoinstall.iso"