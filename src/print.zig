const std = @import("std");
const uefi = std.os.uefi;
const unicode = std.unicode;
const SimpleTextOutputProtocol = uefi.protocols.SimpleTextOutputProtocol;
pub const L  = std.unicode.utf8ToUtf16LeStringLiteral;

pub fn bufPrintLen(buf: []u8, comptime fmt: []const u8, args: anytype) error{NoSpaceLeft}!usize {
    const b = try std.fmt.bufPrint(buf, fmt, args);
    return b.len;
}

pub fn puts(msg: []const u8, con_out: *SimpleTextOutputProtocol) void {
    for (msg) |c| {
        const cu16 = [2]u16{ c, 0 };
        _ = con_out.outputString(@ptrCast(*const [1:0]u16, &cu16));
    }
}

pub fn printf(buf: []u8, comptime format: []const u8, args: anytype, con_out: *SimpleTextOutputProtocol) void {
    const text = std.fmt.bufPrint(buf, format, args) catch |err| {
        handleBufPrintError(err, con_out);
        return;
    };
    puts(text, con_out);
}

pub fn handleBufPrintError(err: error{NoSpaceLeft}, con_out: *SimpleTextOutputProtocol) void {
    if(err == std.fmt.BufPrintError.NoSpaceLeft) {
        puts("bufPrint error: No space left", con_out);
        return;
    }
    puts("bufPrint failed", con_out);
}
