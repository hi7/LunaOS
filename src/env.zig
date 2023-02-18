const std = @import("std");
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Node = ast.Node;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

// immutable
pub const Environment = struct {
    symbols: StringHashMap(*Node),
    parents: []const Environment,
    pub fn deinit(self: *Environment) void {
        self.symbols.deinit();
    }
    pub fn lookup(self: Environment, identifier: []const u8) !?*Node {
        return self.symbols.get(identifier);
    }
};

pub fn createGround(allocator: Allocator) !Environment {
    return Environment {
        .parents = &[0]Environment{},
        .symbols = try groundSymbols(allocator),
    };
}

fn groundSymbols(allocator: Allocator) !StringHashMap(*Node) {
    var symbols = std.StringHashMap(*Node).init(allocator);
    try symbols.put("+", &add);
    return symbols;
}

var add = Node { 
    .list = &[_]Node {  
        Node{ .symbol = "+"},
        Node{ .int = 10},
        Node{ .int = 32 },
    }
};

test "lookup ground" {
    var ground = try createGround(std.testing.allocator);
    defer ground.deinit();

    try expect(try ground.lookup("-") == null);

    const n2 = try ground.lookup("+");
    try expect(n2.?.list.len == 3);
}