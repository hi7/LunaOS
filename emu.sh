#!/bin/sh
qemu-system-x86_64 --enable-kvm -bios /usr/share/edk2/ovmf/OVMF_CODE.fd -hdd fat:rw:. -serial stdio
