const std = @import("std");
const print = @import("print.zig");
const bufPrintLen = print.bufPrintLen;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// immutable
pub const Node = union(enum) {
    boolean: bool,
    int: i64,
    float: f64,
    string: []const u8,
    symbol: []const u8,
    list: []const Node,
};

pub const NodeMutable = union(enum) {
    boolean: bool,
    int: i64,
    float: f64,
    string: []const u8,
    symbol: []const u8,
    list: []const NodeMutable,
};

pub fn writeBuf(buf: []u8, node: *Node, i: usize) error{NoSpaceLeft}!usize {
    var offset: usize = i;
    switch(node.*) {
        .boolean => |boolean| offset += try bufPrintLen(buf[offset..], "{s}", .{ if(boolean) "#t" else "#f"}),
        .int => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .float => |float| offset += try bufPrintLen(buf[offset..], "{d}", .{float}),
        .string => |string| offset += try bufPrintLen(buf[offset..], "{s}", .{string}),
        .symbol => |symbol| offset += try bufPrintLen(buf[offset..], "{s}", .{symbol}),
        .list => |list| {
            offset += try bufPrintLen(buf[offset..], "(", .{});
            for(list) |n, o| {
                var vn = n;
                offset += try writeBuf(buf[(offset)..], &vn, i);
                if(o < (list.len - 1)) offset += try bufPrintLen(buf[offset..], " ", .{});
            }
            offset += try bufPrintLen(buf[(offset)..], ")", .{});
        }
    }
    return offset;
}

fn testNode(node: *Node, expect: []const u8) !void {
    var buf: [309]u8 = undefined;
    const len = try writeBuf(buf[0..], node, 0);
    try std.testing.expectEqual(@as(usize, expect.len), len);
    try std.testing.expectEqualSlices(u8, expect, buf[0..len]);
}

test "write ast bool true" {
    var node = Node{ .boolean = true };
    try testNode(&node, "#t");
}

test "write ast bool false" {
    var node = Node{ .boolean = false };
    try testNode(&node, "#f");
}

test "write ast int 987654321" {
    var node = Node{ .int = 987654321 };
    try testNode(&node, "987654321");
}

test "write ast int -1234567890123456789" {
    var node = Node{ .int = -1234567890123456789 };
    try testNode(&node, "-1234567890123456789");
}

test "write ast float 1234567890123456789" {
    var node = Node{ .float = 12345678901234566 };
    try testNode(&node, "12345678901234566");
}

test "write ast float -.1234567890123456789" {
    var node = Node{ .float = -0.12345678901234566 };
    try testNode(&node, "-0.12345678901234566");
}

test "write ast float 308 digits" {
    var node = Node{ .float = -12345678901234560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 };
    try testNode(&node, "-12345678901234560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
}

test "write ast string abc" {
    var node = Node{ .string = "abc" };
    try testNode(&node, "abc");
}

// TODO test symbol & list
