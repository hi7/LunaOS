const std = @import("std");
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Node = ast.Node;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

var ground: ?EnvironmentImmutable = null;

pub const Environment = union(enum) {
    immutable: EnvironmentImmutable,
    mutable: EnvironmentMutable,
    pub fn symbols(self:Environment) StringHashMap(*Node) {
        return switch(self) {
            .immutable => self.immutable.symbols,
            .mutable => self.mutable.symbols,
        };
    }
    pub fn parents(self:Environment) []Environment {
        return switch(self) {
            .immutable => self.immutable.parents,
            .mutable => self.mutable.parents.items,
        };
    }
    pub fn lookup(self: Environment, identifier: []const u8) ?*Node {
        var s = self.symbols();
        if(s.count() > 0) {
            const local = s.get(identifier);
            if(local != null) return local;
        }
        var p = self.parents();
        for(p) |parent| {
            const result = parent.lookup(identifier);
            if(result != null) return result;
        }
        return null;
    }
    pub fn deinit(self: *Environment) void {
        switch(self.*) {
            .immutable => self.immutable.deinit(),
            .mutable => self.mutable.deinit(),
        }
    }
};

const EnvironmentImmutable = struct {
    symbols: StringHashMap(*Node),
    parents: []Environment,
    pub fn deinit(self: *EnvironmentImmutable) void {
        self.symbols.deinit();
    }
};

pub const EnvironmentMutable = struct {
    symbols: StringHashMap(*Node),
    parents: ArrayList(Environment),
    pub fn init(allocator: Allocator) Allocator.Error!EnvironmentMutable {
        var p = ArrayList(Environment).init(allocator);
        try p.append(Environment{ .immutable = ground.? });
        return EnvironmentMutable{
            .symbols = StringHashMap(*Node).init(allocator),
            .parents = p,
        };
    }
    pub fn deinit(self: *EnvironmentMutable) void {
        self.symbols.deinit();
        self.parents.deinit();
    }
};

pub fn standardEnvironment(allocator: Allocator) Allocator.Error!Environment {
    return Environment{ .mutable = try EnvironmentMutable.init(allocator) };
}

pub fn initGround(allocator: Allocator) Allocator.Error!void {
    ground = EnvironmentImmutable {
        .parents = &[0]Environment{},
        .symbols = try groundSymbols(allocator),
    };
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

pub fn testStdEnv() Allocator.Error!Environment {
    try initGround(std.testing.allocator);
    return try standardEnvironment(std.testing.allocator);
}

pub fn testDeinitEnv(environment: *Environment) void {
    ground.?.deinit();
    environment.deinit();
}

test "lookup ground" {
    try initGround(std.testing.allocator);
    var g = ground.?;
    defer g.deinit();
    var e = Environment{ .immutable = g };

    try expect(e.lookup("-") == null);

    const n2 = e.lookup("+");
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

test "environment define" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);

    const id = "t";
    try expect(e.lookup(id) == null);
    //var node = Node{ .boolean = true };
    //e.define(id, &node);

    const n2 = e.lookup("+");
    try expect(n2.?.list.len == 3);
}