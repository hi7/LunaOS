const std = @import("std");
const ast = @import("ast.zig");
const Node = ast.Node;
const testing = std.testing;
const expectEqual = testing.expectEqual;
const expectEqualSlices = testing.expectEqualSlices;
const expectError = testing.expectError;

pub const Binary = struct {
    len: usize,
    bytes: []const u8,
    fmt: []const u8,
};
// fmt:
// bool u8: 0 => false, otherwise => true

pub const BinError = error {
    FormatNotSupported,
    Length1Expected,
};
pub fn bin2node(bin: *Binary) BinError!Node {
    switch(bin.fmt[0]) {
        'b' => {
            if(bin.fmt[1] == 'o' and bin.fmt[2] == 'o' and bin.fmt[3] == 'l' and bin.fmt[4] == 0) {
                if(bin.len != 1) return BinError.Length1Expected;
                return Node{ .boolean = bin.bytes[0] != 0 };
            }
        },
        else => return BinError.FormatNotSupported,
    }
    return BinError.FormatNotSupported;
}

test "Binary bool" {
    var fail = Binary{ .len = 0, .bytes = &[1]u8{0}, .fmt = &[_]u8{'b', 'o', 'o', 'l', 0} };
    try expectError(BinError.Length1Expected, bin2node(&fail));

    var bf = Binary{ .len = 1, .bytes = &[1]u8{0}, .fmt = &[_]u8{'b', 'o', 'o', 'l', 0} };
    const bfn = try bin2node(&bf);
    try expectEqual(false, bfn.boolean);

    var bt = Binary{ .len = 1, .bytes = &[1]u8{1}, .fmt = &[_]u8{'b', 'o', 'o', 'l', 0} };
    const btn = try bin2node(&bt);
    try expectEqual(true, btn.boolean);
}
