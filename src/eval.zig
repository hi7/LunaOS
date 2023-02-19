const std = @import("std");
const ast = @import("ast.zig");
const Node = ast.Node;
const env = @import("env.zig");
const Environment = env.Environment;
const testStdEnv = env.testStdEnv;
const testDeinitEnv = env.testDeinitEnv;

const EvalError = error {
    SymbolNotBound,
};

pub fn eval(node: *Node, environment: Environment) EvalError!*Node {
    return switch(node.*) {
        .boolean => node,
        .int => node,
        .float => node,
        .string => node,
        .symbol => |symbol| {
            var result = environment.lookup(symbol);
            return if(result == null) error.SymbolNotBound else result.?;
        },
        .list => node, //|list| {
            //for(list) |n, o| {
                //var vn = n;
                // TODO
            //}
        //}
    };
}

test "eval bool" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .boolean = false, };
    const en = try eval(&n, e);
    try std.testing.expectEqual(false, en.boolean );
}

test "eval int" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .int = 42, };
    const en = try eval(&n, e);
    try std.testing.expectEqual(@as(i64, 42), en.int);
}

test "eval float" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .float = 3.141, };
    const en = try eval(&n, e);
    try std.testing.expectEqual(@as(f64, 3.141), en.float);
}

test "eval string" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .string = "a text", };
    const en = try eval(&n, e);
    try std.testing.expectEqualSlices(u8, "a text", en.string);
}

test "eval symbol not found" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .symbol = "-", };
    try std.testing.expectError(error.SymbolNotBound, eval(&n, e));
}

test "eval symbol" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .symbol = "+", };
    try std.testing.expectEqual(&env.add, try eval(&n, e));
}

test "eval list" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var l = [_]Node{
        Node { .boolean = true, },
        Node { .int = 77, },
    };
    var n = Node { .list = l[0..], };
    // TODO operate & apply
    const en = try eval(&n, e);
    try std.testing.expectEqualSlices(Node, l[0..], en.list);
}
