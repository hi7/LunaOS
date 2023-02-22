const std = @import("std");
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;
const ast = @import("ast.zig");
const Node = ast.Node;
const env = @import("env.zig");
const Environment = env.Environment;
const EnvironmentError = env.EnvironmentError;
const testStdEnv = env.testStdEnv;
const testDeinitEnv = env.testDeinitEnv;
const testing = std.testing;
const expectEqual = testing.expectEqual;
const expectEqualSlices = testing.expectEqualSlices;
const expectError = testing.expectError;

pub const EvalError = error {
    SymbolAtFirstPositionExpected,
    SymbolNotBound,
    BooleanExpected,
    NoSpaceLeft,
    Int8Expected,
    Int16Expected,
    Int32Expected,
    Int64Expected,
    Float16Expected,
    Float32Expected,
    Float64Expected,
    SymbolExpected,
    ListExpected,
};

pub fn eval(node: *Node, e: *Environment) EvalError!Node {
    return switch(node.*) {
        .boolean => node.*,
        .int8 => node.*,
        .int16 => node.*,
        .int32 => node.*,
        .int64 => node.*,
        .float16 => node.*,
        .float32 => node.*,
        .float64 => node.*,
        .symbol => |symbol| {
            var n = try e.lookup(symbol);
            return n.*;
        },
        .list => |list| {
            var operator = list[0];
            if(operator != .symbol) return EvalError.SymbolAtFirstPositionExpected;

            var params = list[1..];
            for(params) |expr, i| {
                if(i > 0 and expr == .symbol and expr.symbol[0] != '$') {
                    var vexpr = expr;
                    params[i] = try eval(&vexpr, e);
                }
            }
            return try apply(operator.symbol, params, e);
        }
    };
}

fn add(comptime T: type, a: T, b: T) T {
    return a + b;
}

fn sub(comptime T: type, a: T, b: T) T {
    return a - b;
}

fn mul(comptime T: type, a: T, b: T) T {
    return a * b;
}

fn div(comptime T: type, a: T, b: T) T {
    return @divFloor(a, b);
}

fn neutralElement(node: Node) Node {
    return switch(node) {
        .boolean => Node{ .boolean = true },
        .int8 => Node{ .int8 = 0 },
        .int16 => Node{ .int16 = 0 },
        .int32 => Node{ .int32 = 0 },
        .int64 => Node{ .int64 = 0 },
        .float16 => Node{ .float16 = 0 },
        .float32 => Node{ .float32 = 0 },
        .float64 => Node{ .float64 = 0 },
        .symbol => Node{ .symbol = "" },
        .list => neutralElement(node.list[0]),
    };
}


var buf: [1024]u8 = undefined;
fn applyAdd(params: []Node) EvalError!Node {
    var sum = neutralElement(params[0]);
    return switch(params[0]) {
        .boolean => {
            for(params) |param| {
                if(param != .boolean) return EvalError.BooleanExpected;
                sum.boolean = sum.boolean and param.boolean;
            }
            return Node{ .boolean = sum.boolean };
        },
        .int8 => {
            for(params) |param| {
                if(param != .int8) return EvalError.Int8Expected;
                sum.int8 = sum.int8 + param.int8;
            }
            return Node{ .int8 = sum.int8 };
        },
        .int16 => {
            for(params) |param| {
                if(param != .int16) return EvalError.Int16Expected;
                sum.int16 = sum.int16 + param.int16;
            }
            return Node{ .int16 = sum.int16};
        },
        .int32 => {
            for(params) |param| {
                if(param != .int32) return EvalError.Int32Expected;
                sum.int32 = sum.int32 + param.int32;
            }
            return Node{ .int32 = sum.int32};
        },
        .int64 => {
            for(params) |param| {
                if(param != .int64) return EvalError.Int64Expected;
                sum.int64 = sum.int64 + param.int64;
            }
            return Node{ .int64 = sum.int64};
        },
        .float16 => {
            for(params) |param| {
                if(param != .float16) return EvalError.Float16Expected;
                sum.float16 = sum.float16 + param.float16;
            }
            return Node{ .float16 = sum.float16};
        },
        .float32 => {
            for(params) |param| {
                if(param != .float32) return EvalError.Float16Expected;
                sum.float32 = sum.float32 + param.float32;
            }
            return Node{ .float32 = sum.float32};
        },
        .float64 => {
            for(params) |param| {
                if(param != .float64) return EvalError.Float16Expected;
                sum.float64 = sum.float64 + param.float64;
            }
            return Node{ .float64 = sum.float64};
        },
        .symbol => {
            var len: usize = 0;
            for(params) |param| {
                if(param != .symbol) return EvalError.SymbolExpected;
                var sym = try std.fmt.bufPrint(buf[len..], "{s}", .{ param.symbol });
                len += sym.len;
            }
            return Node{ .symbol = buf[0..len] };
        },
        .list => {
            for(params) |param| {
                for(param.list) |par| {
                    var p = [_]Node{ sum, par };
                    sum = try applyAdd(&p);
                }
            }
            return sum;
        }
    };
}

pub fn apply(symbol: []const u8, params: []Node, e: *Environment) EvalError!Node {
    return switch(symbol[0]) {
        '+' => try applyAdd(params),
        '-' => Node{ .int8 = sub(i8, params[0].int8, params[1].int8)},
        '*' => Node{ .int8 = mul(i8, params[0].int8, params[1].int8)},
        '/' => Node{ .int8 = div(i8, params[0].int8, params[1].int8)},
        else => {
            _ = try e.lookup(symbol);
            return Node{ .int8 = 99 };
        }
    };
}

test "eval bool" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .boolean = false, };
    const en = try eval(&n, &e);
    try expectEqual(false, en.boolean );
}

test "eval int" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .int8 = 42, };
    const en = try eval(&n, &e);
    try expectEqual(@as(i8, 42), en.int8);
}

test "eval float" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .float16 = 3.141, };
    const en = try eval(&n, &e);
    try expectEqual(@as(f16, 3.141), en.float16);
}

test "eval symbol not bound" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .symbol = "-", };
    try expectError(error.SymbolNotBound, eval(&n, &e));
}

test "eval symbol" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var n = Node { .symbol = "test", };
    try expectEqual(env.testNode, try eval(&n, &e));
}

test "eval list no symbol" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var l = [_]Node{
        Node { .boolean = true, },
        Node { .int8 = 77, },
    };
    var n = Node { .list = l[0..], };
    try expectError(EvalError.SymbolAtFirstPositionExpected, eval(&n, &e));
}

test "eval call type missmatch" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var l = [_]Node{
        Node { .symbol = "+", },
        Node { .int16 = 7, },
        Node { .int32 = 2, },
    };
    var n = Node { .list = l[0..], };
    try expectError(EvalError.Int16Expected, eval(&n, &e));
}

test "eval call add 2x int8" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var l = [_]Node{
        Node { .symbol = "+", },
        Node { .int8 = 77, },
        Node { .int8 = 22, },
    };
    var n = Node { .list = l[0..], };
    try expectEqual(Node{ .int8 = 99 }, try eval(&n, &e));
}

test "eval call add 3x int8" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var l = [_]Node{
        Node { .symbol = "+", },
        Node { .int8 = 11, },
        Node { .int8 = 22, },
        Node { .int8 = 33, },
    };
    var n = Node { .list = l[0..], };
    try expectEqual(Node{ .int8 = 66 }, try eval(&n, &e));
}

test "eval call add 3x symbol" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var l = [_]Node{
        Node { .symbol = "+" },
        Node { .symbol = "test" },
        Node { .symbol = "test" },
        Node { .symbol = "test" },
    };
    var n = Node { .list = l[0..], };
    try expectEqualSlices(u8, "testtesttest", (try eval(&n, &e)).symbol);
}
test "eval call add float16" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var l = [_]Node{
        Node { .symbol = "+", },
        Node { .float16 = 7.7, },
        Node { .float16 = 2.2, },
    };
    var n = Node { .list = l[0..], };
    try expectEqual(Node{ .float16 = 9.9 }, try eval(&n, &e));
}

test "eval call add list int16" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var i = [_]Node{
        Node { .int16 = 11, },
        Node { .int16 = 22, },
        Node { .int16 = 33, },
    };
    var l = [_]Node{
        Node { .symbol = "+", },
        Node { .list = &i },
    };
    var n = Node { .list = l[0..], };
    try expectEqual(Node{ .int16 = 66 }, try eval(&n, &e));
}

test "eval call add lists float16" {
    var e = try testStdEnv();
    defer testDeinitEnv(&e);
    var as = [_]Node{
        Node { .float16 = 111.0 },
        Node { .float16 = 222.0 },
        Node { .float16 = 333.0 },
    };
    var bs = [_]Node{
        Node { .float16 = 444.0 },
        Node { .float16 = 555.0 },
        Node { .float16 = 666.0 },
    };
    var l = [_]Node{
        Node { .symbol = "+", },
        Node { .list = &as },
        Node { .list = &bs },
    };
    var n = Node { .list = l[0..], };
    try expectEqual(Node{ .float16 = 2332.0 }, try eval(&n, &e));
}
