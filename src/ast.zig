const std = @import("std");
const print = @import("print.zig");
const bufPrintLen = print.bufPrintLen;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Node = union(enum) {
    boolean: bool,
    intU8: u8,
    int8: i8,
    intU16: i16,
    int16: i16,
    intU32: i32,
    int32: i32,
    intU64: i64,
    int64: i64,
    float16: f16,
    float32: f32,
    float64: f64,
    symbol: []const u8,
    list: []Node,
};

pub const EnvNode = struct {
    nodeLba: ?u64,
    x86_64Lba: ?u64,
    node: ?Node,
};

pub fn writeBuf(comptime ascii: bool, buf: []u8, node: *Node, i: usize) error{NoSpaceLeft}!usize {
    var offset: usize = i;
    switch(node.*) {
        .boolean => |boolean| offset += try bufPrintLen(buf[offset..], "{s}", .{ if(boolean) "#t" else "#f"}),
        .intU8 => |int| offset += try bufPrintLen(buf[offset..], if(ascii) "{c}" else "{d}", .{int}),
        .int8 => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .intU16 => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .int16 => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .intU32 => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .int32 => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .intU64 => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .int64 => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .float16 => |float| offset += try bufPrintLen(buf[offset..], "{d}", .{float}),
        .float32 => |float| offset += try bufPrintLen(buf[offset..], "{d}", .{float}),
        .float64 => |float| offset += try bufPrintLen(buf[offset..], "{d}", .{float}),
        .symbol => |symbol| offset += try bufPrintLen(buf[offset..], "{s}", .{symbol}),
        .list => |list| {
            if(!ascii) offset += try bufPrintLen(buf[offset..], "(", .{});
            for(list) |n, o| {
                var vn = n;
                offset += try writeBuf(ascii, buf[(offset)..], &vn, i);
                if(!ascii and o < (list.len - 1)) offset += try bufPrintLen(buf[offset..], " ", .{});
            }
            if(!ascii) offset += try bufPrintLen(buf[(offset)..], ")", .{});
        }
    }
    return offset;
}

fn testNode(comptime ascii: bool, node: *Node, expect: []const u8) !void {
    var buf: [309]u8 = undefined;
    const len = try writeBuf(ascii, buf[0..], node, 0);
    //std.debug.print("\n>>{s}<<\n", .{buf[0..len]});
    try std.testing.expectEqual(@as(usize, expect.len), len);
    try std.testing.expectEqualSlices(u8, expect, buf[0..len]);
}

test "write ast bool true" {
    var node = Node{ .boolean = true };
    try testNode(false, &node, "#t");
}

test "write ast bool false" {
    var node = Node{ .boolean = false };
    try testNode(false, &node, "#f");
}

test "write ast int 987654321" {
    var node = Node{ .int32 = 987654321 };
    try testNode(false, &node, "987654321");
}

test "write ast int -1234567890123456789" {
    var node = Node{ .int64 = -1234567890123456789 };
    try testNode(false, &node, "-1234567890123456789");
}

test "write ast float 1234567890123456789" {
    var node = Node{ .float64 = 12345678901234566 };
    try testNode(false, &node, "12345678901234566");
}

test "write ast float -.1234567890123456789" {
    var node = Node{ .float64 = -0.12345678901234566 };
    try testNode(false, &node, "-0.12345678901234566");
}

test "write ast float 308 digits" {
    var node = Node{ .float64 = -12345678901234560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 };
    try testNode(false, &node, "-12345678901234560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
}

test "write ast string abc" {
    var list = [_]Node{ 
        Node{ .intU8 = 'a' },
        Node{ .intU8 = 'b' },
        Node{ .intU8 = 'c' },
    };
    var node = Node{ .list = &list};
    try testNode(true, &node, "abc");
}

// TODO test symbol & list
