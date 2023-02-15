const std = @import("std");
const uefi = std.os.uefi;
const unicode = std.unicode;
pub const L  = std.unicode.utf8ToUtf16LeStringLiteral;

pub fn bufPrintLen(buf: []u8, comptime fmt: []const u8, args: anytype) usize {
    const b = std.fmt.bufPrint(buf, fmt, args) catch unreachable;
    return b.len;
}

pub fn puts(msg: []const u8, con_out: *uefi.protocols.SimpleTextOutputProtocol) void {
    for (msg) |c| {
        const cu16 = [2]u16{ c, 0 };
        _ = con_out.outputString(@ptrCast(*const [1:0]u16, &cu16));
    }
}

pub fn printf(buf: []u8, comptime format: []const u8, args: anytype) void {
    puts(std.fmt.bufPrint(buf, format, args) catch unreachable);
}
