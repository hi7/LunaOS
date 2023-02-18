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

    var buf: [256]u8 = undefined;
    env.init(std.os.uefi.pool_allocator) catch |err| {
        print.printf(&buf, "Error: {}\r\n", .{err}, con_out);
    };
    defer env.deinit();

    printAst(&buf, con_out);

    fin();
}

fn printAst(buf: []u8, con_out: *SimpleTextOutputProtocol) void {
    var buffer = buf;
    const len: usize = ast.outputAst(buffer, 0, lookup(buffer, "+", con_out)) catch |err| {
        print.handleBufPrintError(err, con_out);
        return;
    };
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
    var result = env.ground.lookup(identifier) catch |err| {
        print.printf(buf, "Error: {}\r\n", .{err}, con_out);
        fin();
    };
    if(result == null) {
        print.printf(buf, "Symbol {s} is not bound in environment\r\n", .{identifier}, con_out);
        fin();
    }
    return result.?;
}
