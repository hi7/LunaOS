#!/bin/sh
sudo mount /dev/sda1 mnt
sudo cp efi/boot/bootx64.efi mnt/efi/boot/
sudo umount /dev/sda1
echo 'done!'