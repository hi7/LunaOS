const std = @import("std");
const ast = @import("ast.zig");
const Node = ast.Node;
const expect = std.testing.expect;

pub var ground: Environment = undefined;

const Environment = struct {
    symbols: std.StringHashMap(*Node),
    fn deinit(self: *Environment) void {
        self.symbols.deinit();
    }
    pub fn lookup(self: Environment, identifier: []const u8) !?*Node {
        return self.symbols.get(identifier);
    }
};

pub fn init(allocator: std.mem.Allocator) void {
    ground = Environment {
        .symbols = std.StringHashMap(*Node).init(allocator),
    };
    ground.symbols.put("+", &add) catch unreachable;
}

pub fn deinit() void {
    ground.deinit();
}

var add = Node { 
    .list = &[_]Node {  
        Node{ .symbol = "+"},
        Node{ .int = 10},
        Node{ .int = 32 },
    }
};

test "lookup evironment" {
    init(std.testing.allocator);
    defer deinit();

    try expect(try ground.lookup("-") == null);

    const n2 = try ground.lookup("+");
    try expect(n2.?.list.len == 3);
}