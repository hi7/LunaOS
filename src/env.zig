const std = @import("std");
const ast = @import("ast.zig");
const Node = ast.Node;

var symbols: std.StringHashMap(*Node) = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    symbols = std.StringHashMap(*Node).init(allocator);
    symbols.put("+", &add) catch unreachable;
}

pub fn deinit() void {
    symbols.deinit();
}

pub fn lookup(identifier: []const u8) !?*Node {
    return symbols.get(identifier);
}

var add = Node { 
    .list = &[_]Node {  
        Node{ .symbol = "+"},
        Node{ .int = 10},
        Node{ .int = 32 },
    }
};
