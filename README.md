# LunaOS
UEFI app written in Zig Version 0.11.0-dev

# Build
`zig build`

# Boot from device e.g. USB
Copy `efi/boot/bootx64.efi` to a FAT32 formatted device.

# Run in Qemu on Fedora Linux
`zig build run`  
With `/usr/share/edk2/ovmf/OVMF_CODE.fd` 
and `/usr/share/edk2/ovmf/OVMF_VARS.fd` 
see `run_cmd` in `build.zig`.

# Or run it with a shell script
`./emu.sh`
