const std = @import("std");
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Node = ast.Node;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

var ground: ?Environment = null;

const EnvironmentError = error{ 
    EnvironmentIsImmutable,
    OutOfMemory,
    GroundNotInitialized,
};

pub const Environment = struct {
    symbols: StringHashMap(*Node),
    parents: ?ArrayList(Environment),
    mutable: bool,
    pub fn grd(allocator: Allocator) EnvironmentError!Environment {
        return Environment{
            .parents = null,
            .symbols = try groundSymbols(allocator),
            .mutable = false,
        };
    }
    pub fn std(allocator: Allocator) EnvironmentError!Environment {
        var p = ArrayList(Environment).init(allocator);
        if(ground == null) return EnvironmentError.GroundNotInitialized;
        try p.append(ground.?);
        return Environment{
            .symbols = StringHashMap(*Node).init(allocator),
            .parents = p,
            .mutable = true,
        };
    }
    pub fn initImmutable(symbols: StringHashMap(*Node), parents: ArrayList(Environment)) Allocator.Error!Environment {
        return Environment{
            .symbols = symbols,
            .parents = parents,
            .mutable = false,
        };
    }
    pub fn deinit(self: *Environment) void {
        self.symbols.deinit();
        if(self.parents != null) self.parents.?.deinit();
    }
    pub fn defineMut(self: Environment, identifier: []const u8, node: *Node) EnvironmentError!void {
        if(!self.mutable) return EnvironmentError.EnvironmentIsImmutable;
        var s = self.symbols;
        try s.put(identifier, node);
    }
    pub fn lookup(self: Environment, identifier: []const u8) ?*Node {
        var s = self.symbols;
        if(s.count() > 0) {
            const local = s.get(identifier);
            if(local != null) return local;
        }
        var p = self.parents;
        if(p != null) {
            for(p.?.items) |parent| {
                const result = parent.lookup(identifier);
                if(result != null) return result;
            }
        }
        return null;
    }
};

pub fn initGround(allocator: Allocator) EnvironmentError!void {
    ground = try Environment.grd(allocator);
}

fn groundSymbols(allocator: Allocator) Allocator.Error!StringHashMap(*Node) {
    var symbols = std.StringHashMap(*Node).init(allocator);
    try symbols.put("+", &add);
    return symbols;
}

pub var add = Node { 
    .list = &[_]Node {  
        Node{ .symbol = "+"},
        Node{ .int = 10},
        Node{ .int = 32 },
    }
};

pub fn testStdEnv() EnvironmentError!Environment {
    ground = try Environment.grd(std.testing.allocator);
    return try Environment.std(std.testing.allocator);
}

pub fn testDeinitEnv(environment: *Environment) void {
    ground.?.deinit();
    environment.deinit();
}

test "lookup ground" {
    ground = try Environment.grd(std.testing.allocator);
    defer ground.?.deinit();

    try expect(ground.?.lookup("-") == null);
    const n2 = ground.?.lookup("+");
    try expect(n2.?.list.len == 3);
}

test "standard environment lookup" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);

    try expect(e.lookup("-") == null);
    const n2 = e.lookup("+");
    try expect(n2.?.list.len == 3);
}

test "environment lookup" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);

    try expect(e.lookup("-") == null);
    const n2 = e.lookup("+");
    try expect(n2.?.list.len == 3);
}

test "environment defineMut" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);

    const id = "a";
    try expect(e.lookup(id) == null);
    //var node = Node{ .boolean = true };
    //try e.defineMut(id, &node);

    const n2 = e.lookup("+");
    try expect(n2.?.list.len == 3);
}