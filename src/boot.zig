const std = @import("std");
const uefi = std.os.uefi;
const unicode = std.unicode;
const print = @import("print.zig");
const SimpleTextOutputProtocol = uefi.protocols.SimpleTextOutputProtocol;
const env = @import("env.zig");
const Environment = env.Environment;
const ast = @import("ast.zig");
const Node = ast.Node;

pub fn main() void {
    const con_out = uefi.system_table.con_out.?;
    printHeader(con_out);

    var buf: [256]u8 = undefined;
    env.initGround(std.os.uefi.pool_allocator) catch |err| {
        print.printf(&buf, "initGround error: {}\r\n", .{err}, con_out);
        return;
    };
    var e = env.standardEnvironment(std.os.uefi.pool_allocator) catch |err| {
        print.printf(&buf, "standardEnvironment error: {}\r\n", .{err}, con_out);
        return;
    };
    defer e.deinit();

    printAst(e, &buf, con_out);

    fin();
}

fn printAst(environment: Environment, buf: []u8, con_out: *SimpleTextOutputProtocol) void {
    var buffer = buf;
    const node = lookup(environment, buffer, "+", con_out).?;
    const len: usize = ast.writeBuf(buffer, node, 0) catch |err| {
        print.handleBufPrintError(err, con_out);
        return;
    };
    print.puts(buf[0..len], con_out);
}

fn printHeader(con_out: *SimpleTextOutputProtocol) void {
    _ = con_out.reset(false);
    _ = con_out.outputString(print.L("LunaOS\r\n\n"));
}

fn lookup(environment: Environment, buf: []u8, identifier: []const u8, con_out: *SimpleTextOutputProtocol) ?*Node {
    var result = environment.lookup(identifier);
    if(result == null) {
        print.printf(buf, "Symbol {s} is not bound in environment\r\n", .{identifier}, con_out);
    }
    return result;
}

fn fin() void {
    const boot_services = uefi.system_table.boot_services.?;
    _ = boot_services.setWatchdogTimer(0, 0, 0, null);
    //_ = boot_services.stall(5_000_000);
    while (true) {}
}
