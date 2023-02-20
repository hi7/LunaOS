const std = @import("std");
const Target = std.Target;
const Build = std.Build;
const FileSource = Build.FileSource;
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = CrossTarget{
        .cpu_arch = Target.Cpu.Arch.x86_64,
        .os_tag = Target.Os.Tag.uefi,
        .abi = Target.Abi.msvc,
    };
    const root_source_file = FileSource{
        .path = "src/boot.zig",
    };
    const exe = b.addExecutable(.{
        .name = "bootx64", 
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
    });
    exe.setOutputDir("efi/boot");
    b.default_step.dependOn(&exe.step);

    const run_cmd = b.addSystemCommand(&[_][]const u8{
        "qemu-system-x86_64",
        "--enable-kvm",
        "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/edk2/ovmf/OVMF_CODE.fd",
        "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/edk2/ovmf/OVMF_VARS.fd",
        "-kernel", "efi/boot/bootx64.efi",
        "-hdd", "fat:rw:.",
        // "-serial", "stdio",
    });
    run_cmd.step.dependOn(b.getInstallStep());

    const run = b.step("run", "run in qemu");
    run.dependOn(&run_cmd.step);
}
