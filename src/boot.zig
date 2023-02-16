const std = @import("std");
const uefi = std.os.uefi;
const unicode = std.unicode;
const print = @import("print.zig");
const SimpleTextOutputProtocol = uefi.protocols.SimpleTextOutputProtocol;
const env = @import("env.zig");
const ast = @import("ast.zig");
const Node = ast.Node;

pub fn main() void {
    const con_out = uefi.system_table.con_out.?;
    printHeader(con_out);

    env.init(std.os.uefi.pool_allocator);
    defer env.deinit();

    printAst(con_out);

    fin();
}

fn printAst(con_out: *SimpleTextOutputProtocol) void {
    var buf: [256]u8 = undefined;
    const len = ast.outputAst(&buf, 0, lookup(&buf, "+", con_out));
    print.puts(buf[0..len], con_out);
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

fn lookup(buf: []u8, identifier: []const u8, con_out: *SimpleTextOutputProtocol) *Node {
    var result = env.lookup(identifier) catch |err| {
        print.printf(buf, "error: {}\r\n", .{err}, con_out);
        fin();
    };
    if(result == null) {
        print.printf(buf, "symbol {s} is not in environment\r\n", .{identifier}, con_out);
        fin();
    }
    return result.?;
}
