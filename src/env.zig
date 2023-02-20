const std = @import("std");
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Node = ast.Node;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

var ground: ?Environment = null;

pub const EnvironmentError = error{ 
    EnvironmentIsImmutable,
    OutOfMemory,
    GroundNotInitialized,
    SymbolNotBound,
};

pub const Environment = struct {
    symbols: StringHashMap(*Node),
    parents: ?ArrayList(Environment),
    mutable: bool,
    pub fn makeGroundEnvironment(allocator: Allocator) EnvironmentError!Environment {
        return Environment{
            .parents = null,
            .symbols = try groundSymbols(allocator),
            .mutable = false,
        };
    }
    pub fn makeStandardEnvironment(allocator: Allocator) EnvironmentError!Environment {
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
    pub fn defineMut(self: *Environment, identifier: []const u8, node: *Node) EnvironmentError!void {
        if(!self.mutable) return EnvironmentError.EnvironmentIsImmutable;
        try self.symbols.put(identifier, node);
    }
    pub fn lookup(self: *Environment, identifier: []const u8) error{SymbolNotBound}!*Node {
        if(self.symbols.count() > 0) {
            const local = self.symbols.get(identifier);
            if(local != null) return local.?;
        }
        if(self.parents != null) {
            for(self.parents.?.items) |parent| {
                var p = parent;
                const result = p.lookup(identifier);
                if(result != EnvironmentError.SymbolNotBound) return result;
            }
        }
        return EnvironmentError.SymbolNotBound;
    }
};

pub fn init(allocator: Allocator) EnvironmentError!void {
    ground = try Environment.makeGroundEnvironment(allocator);
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
    ground = try Environment.makeGroundEnvironment(std.testing.allocator);
    return try Environment.makeStandardEnvironment(std.testing.allocator);
}

pub fn testDeinitEnv(environment: *Environment) void {
    ground.?.deinit();
    environment.deinit();
}

test "ground defineMut" {
    ground = try Environment.makeGroundEnvironment(std.testing.allocator);
    defer ground.?.deinit();

    var node = Node{ .int = 2077 };
    try expectError(EnvironmentError.EnvironmentIsImmutable, ground.?.defineMut("a", &node));
}

test "ground lookup" {
    ground = try Environment.makeGroundEnvironment(std.testing.allocator);
    defer ground.?.deinit();

    try expectError(EnvironmentError.SymbolNotBound, ground.?.lookup("-"));
    const n = try ground.?.lookup("+");
    try expect(n.list.len == 3);
}

test "standard environment lookup" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);

    try expectError(EnvironmentError.SymbolNotBound, e.lookup("-"));
    const n = try e.lookup("+");
    try expect(n.list.len == 3);
}

test "environment lookup" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);

    try expectError(EnvironmentError.SymbolNotBound, e.lookup("-"));
    const n = try e.lookup("+");
    try expect(n.list.len == 3);
}

test "environment defineMut error" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    try expectError(EnvironmentError.SymbolNotBound, e.lookup("a"));
}

test "environment defineMut" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);

    const id = "a";
    try expectError(EnvironmentError.SymbolNotBound, e.lookup("a"));
    var node = Node{ .boolean = true };
    try e.defineMut(id, &node);

    const a = try e.lookup("a");
    try expect(a.boolean == true);
}
