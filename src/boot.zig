const uefi = @import("std").os.uefi;
const L  = @import("std").unicode.utf8ToUtf16LeStringLiteral;

pub fn main() void {
    const con_out = uefi.system_table.con_out.?;
    _ = con_out.reset(false);
    _ = con_out.outputString(L("LunaOS\r\n"));
    const boot_services = uefi.system_table.boot_services.?;
    _ = boot_services.stall(5_000_000);
    // back to EFI
}
