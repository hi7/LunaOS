const std = @import("std");
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Node = ast.Node;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

var ground: ?EnvironmentImmutable = null;

const Environment = union(enum) {
    immutable: EnvironmentImmutable,
    mutable: EnvironmentMutable,
    pub fn lookup(self: Environment, identifier: []const u8) ?*Node {
        switch(self) {
            .immutable => return self.immutable.symbols.get(identifier),
            .mutable => return self.mutable.symbols.get(identifier),
        }        
    }
    pub fn deinit(self: Environment) void {
        switch(self) {
            .immutable => return self.immutable.deinit(),
            .mutable => return self.mutable.deinit(),
        }
    }
};

const EnvironmentImmutable = struct {
    symbols: StringHashMap(*Node),
    parents: []Environment,
    pub fn deinit(self: *EnvironmentImmutable) void {
        self.symbols.deinit();
    }
    pub fn lookup(self: EnvironmentImmutable, identifier: []const u8) ?*Node {
        return self.symbols.get(identifier);
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
    pub fn lookup(self: EnvironmentMutable, identifier: []const u8) ?*Node {
        if(self.symbols.count() == 0) {
            for(self.parents.items) |parent| {
                const result = parent.lookup(identifier);
                if(result != null) return result;
            }
        }
        return self.symbols.get(identifier);
    }
};

pub fn standardEnvironment(allocator: Allocator) Allocator.Error!EnvironmentMutable {
    return EnvironmentMutable.init(allocator);
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

var add = Node { 
    .list = &[_]Node {  
        Node{ .symbol = "+"},
        Node{ .int = 10},
        Node{ .int = 32 },
    }
};

test "lookup ground" {
    try initGround(std.testing.allocator);
    var g = ground.?;
    defer g.deinit();

    try expect(g.lookup("-") == null);

    const n2 = g.lookup("+");
    try expect(n2.?.list.len == 3);
}

test "lookup standard environment" {
    try initGround(std.testing.allocator);
    defer ground.?.deinit();
    var std_env = try standardEnvironment(std.testing.allocator);
    defer std_env.deinit();

    try expect(std_env.lookup("-") == null);

    const n2 = std_env.lookup("+");
    try expect(n2.?.list.len == 3);
}