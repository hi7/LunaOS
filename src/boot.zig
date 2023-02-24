const std = @import("std");
const uefi = std.os.uefi;
const Status = uefi.Status;
const unicode = std.unicode;
const print = @import("print.zig");
const BootServices = uefi.tables.BootServices;
const SimpleTextOutputProtocol = uefi.protocols.SimpleTextOutputProtocol;
const BlockIoProtocol = uefi.protocols.BlockIoProtocol;
const env = @import("env.zig");
const Environment = env.Environment;
const ast = @import("ast.zig");
const Node = ast.Node;
const eval = @import("eval.zig").eval;
const io = @import("io.zig");

pub fn main() void {
    var buf: [1024]u8 = undefined;
    const boot_services = uefi.system_table.boot_services.?;
    _ = boot_services.setWatchdogTimer(0, 0, 0, null);
    const con_out = uefi.system_table.con_out.?;

    printHeader(con_out);
    readBlock(&buf, boot_services, con_out);

    const environment = envInit(&buf, con_out);
    if(environment == null) return;
    var e = environment.?;
    defer e.deinit();

    var call = [_]Node{
        Node { .symbol = "+", },
        Node { .int32 = 123, },
        Node { .int32 = 456, },
        Node { .int32 = 789, },
    };
    var node = Node { .list = call[0..] };
    print.puts("\r\n", con_out);
    printAst(&node, &e, &buf, con_out);
    _ = boot_services.stall(1_000_000);
    print.puts(" => ", con_out);
    _ = boot_services.stall(1_000_000);
    printEval(&node, &e, &buf, con_out);

    fin();
}

fn envInit(buf: []u8, con_out: *SimpleTextOutputProtocol) ?Environment {
    var buffer = buf;
    env.init(std.os.uefi.pool_allocator) catch |err| {
        print.printf(buffer, "environment init error: {}\r\n", .{err}, con_out);
        return null;
    };
    return Environment.makeStandardEnvironment(std.os.uefi.pool_allocator) catch |err| {
        print.printf(buffer, "make standard environment error: {}\r\n", .{err}, con_out);
        return null;
    };
}

fn readBlock(buf: []u8, boot_services: *BootServices, con_out: *SimpleTextOutputProtocol) void {
    var buffer = buf;
    const blockSize = io.init(boot_services) catch |err| {
        print.printf(buffer, "block io init error: {}\r\n", .{err}, con_out);
        return;
    };
    if(blockSize <= 512){
        var data: [512]u8 = undefined;
        io.readBlock(io.minLba, 512, &data) catch |err| {
            print.printf(buffer, "environment init error: {}\r\n", .{err}, con_out);
            return;
        };
        print.puts("block io at lba 10: ", con_out);
        print.printf(buffer, "{s}", .{std.fmt.fmtSliceHexLower(data[0..512])}, con_out);
    } else {
        print.printf(buffer, "block size > 512: {d}\r\n", .{blockSize}, con_out);
        return;
    }
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
    while (true) {}
}
