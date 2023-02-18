const std = @import("std");
const ast = @import("ast.zig");
const Node = ast.Node;
const env = @import("env.zig");
const Environment = env.Environment;
const testInitStdEnv = env.testInitStdEnv;
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
    var std_env = try testInitStdEnv();
    defer testDeinitEnv(&std_env);
    var n = Node { .boolean = false, };
    const en = try eval(&n, Environment{ .mutable = std_env});
    try std.testing.expectEqual(false, en.boolean );
}

test "eval int" {
    var std_env = try testInitStdEnv();
    defer testDeinitEnv(&std_env);
    var n = Node { .int = 42, };
    const en = try eval(&n, Environment{ .mutable = std_env});
    try std.testing.expectEqual(@as(i64, 42), en.int);
}

test "eval float" {
    var std_env = try testInitStdEnv();
    defer testDeinitEnv(&std_env);
    var n = Node { .float = 3.141, };
    const en = try eval(&n, Environment{ .mutable = std_env});
    try std.testing.expectEqual(@as(f64, 3.141), en.float);
}

test "eval string" {
    var std_env = try testInitStdEnv();
    defer testDeinitEnv(&std_env);
    var n = Node { .string = "a text", };
    const en = try eval(&n, Environment{ .mutable = std_env});
    try std.testing.expectEqualSlices(u8, "a text", en.string);
}

test "eval symbol not found" {
    var std_env = try testInitStdEnv();
    var mut_env = Environment{ .mutable = std_env};
    defer testDeinitEnv(&std_env);
    var n = Node { .symbol = "-", };
    try std.testing.expectError(error.SymbolNotBound, eval(&n, mut_env));
}

test "eval symbol" {
    var std_env = try testInitStdEnv();
    var mut_env = Environment{ .mutable = std_env};
    defer testDeinitEnv(&std_env);
    var n = Node { .symbol = "+", };
    try std.testing.expectEqual(&env.add, try eval(&n, mut_env));
}

test "eval list" {
    var std_env = try testInitStdEnv();
    defer testDeinitEnv(&std_env);
    var l = [_]Node{
        Node { .boolean = true, },
        Node { .int = 77, },
    };
    var n = Node { .list = l[0..], };
    // TODO operate & apply
    const en = try eval(&n, Environment{ .mutable = std_env});
    try std.testing.expectEqualSlices(Node, l[0..], en.list);
}
