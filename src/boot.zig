const std = @import("std");
const uefi = std.os.uefi;
const unicode = std.unicode;
const print = @import("print.zig");
const SimpleTextOutputProtocol = uefi.protocols.SimpleTextOutputProtocol;
const env = @import("env.zig");
const Environment = env.Environment;
const ast = @import("ast.zig");
const Node = ast.Node;
const eval = @import("eval.zig").eval;

pub fn main() void {
    const con_out = uefi.system_table.con_out.?;
    printHeader(con_out);

    var buf: [256]u8 = undefined;
    env.init(std.os.uefi.pool_allocator) catch |err| {
        print.printf(&buf, "environment init error: {}\r\n", .{err}, con_out);
        return;
    };
    var e = Environment.makeStandardEnvironment(std.os.uefi.pool_allocator) catch |err| {
        print.printf(&buf, "make standard environment error: {}\r\n", .{err}, con_out);
        return;
    };
    defer e.deinit();

    var call = [_]Node{
        Node { .symbol = "+", },
        Node { .int32 = 123, },
        Node { .int32 = 456, },
        Node { .int32 = 789, },
    };
    var node = Node { .list = call[0..] };
    printAst(&node, &e, &buf, con_out);
    print.puts(" => ", con_out);
    printEval(&node, &e, &buf, con_out);

    fin();
}

fn printAst(node: *Node, _: *Environment, buf: []u8, con_out: *SimpleTextOutputProtocol) void {
    var buffer = buf;

    const len: usize = ast.writeBuf(false, buffer, node, 0) catch |err| {
        print.handleBufPrintError(err, con_out);
        return;
    };
    print.puts(buf[0..len], con_out);
}

fn printEval(node: *Node, e: *Environment, buf: []u8, con_out: *SimpleTextOutputProtocol) void {
    var result = eval(node, e) catch |err| {
        print.printf(buf, "eval error: {}\r\n", .{err}, con_out);
        return;
    };
    printAst(&result, e, buf, con_out);
}

fn printHeader(con_out: *SimpleTextOutputProtocol) void {
    _ = con_out.reset(false);
    _ = con_out.outputString(print.L("LunaOS\r\n\n"));
}

fn fin() void {
    const boot_services = uefi.system_table.boot_services.?;
    _ = boot_services.setWatchdogTimer(0, 0, 0, null);
    //_ = boot_services.stall(5_000_000);
    while (true) {}
}
