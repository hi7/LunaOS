# LunaOS
UEFI app written in Zig Version 0.11.0-dev

# Build
`zig build`

# Boot from device e.g. USB
Copy `efi/boot/bootx64.efi` to a FAT32 formatted device.

# Run in Qemu on Fedora Linux
`zig build run`
With `/usr/share/edk2/ovmf/OVMF_CODE.fd` as BIOS (see `build.zig` -> `run_cmd`).

Or directly:
`qemu-system-x86_64 --enable-kvm -bios /usr/share/edk2/ovmf/OVMF_CODE.fd -hdd fat:rw:. -serial stdio`
