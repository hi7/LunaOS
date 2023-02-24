const std = @import("std");
const uefi = std.os.uefi;
const Status = uefi.Status;
const unicode = std.unicode;
const print = @import("print.zig");
const SimpleTextOutputProtocol = uefi.protocols.SimpleTextOutputProtocol;
const BlockIoProtocol = uefi.protocols.BlockIoProtocol;
const env = @import("env.zig");
const Environment = env.Environment;
const ast = @import("ast.zig");
const Node = ast.Node;
const eval = @import("eval.zig").eval;

pub fn main() void {
    var buf: [4096]u8 = undefined;
    const boot_services = uefi.system_table.boot_services.?;
    _ = boot_services.setWatchdogTimer(0, 0, 0, null);
    const con_out = uefi.system_table.con_out.?;

    printHeader(con_out);

    var blockIoProtocol: ?*BlockIoProtocol = undefined;
    if(boot_services.locateProtocol(&BlockIoProtocol.guid, null, @ptrCast(*?*anyopaque, &blockIoProtocol)) == Status.Success) {
        print.printf(&buf, "IO block size: {d}\r\n", .{blockIoProtocol.?.media.block_size}, con_out);
        var handleCount: usize = undefined;
        var handles: [*]uefi.Handle = undefined;
        const ByProtocol = uefi.tables.LocateSearchType.ByProtocol;
        const statusHandle = boot_services.locateHandleBuffer(ByProtocol, &BlockIoProtocol.guid, null, &handleCount, &handles);
        if(statusHandle == Status.Success) {
            if(handleCount > 0) {
                var blockIo = boot_services.openProtocolSt(BlockIoProtocol, handles[0]) catch |err| {
                    print.printf(&buf, "openProtocolSt BlockIoProtocol error: {}\r\n", .{err}, con_out);
                    return;
                };
                var data: [512]u8 = undefined;
                const lba: u64 = 1;
                if(blockIo.readBlocks(blockIoProtocol.?.media.media_id, lba, 512, &data) == Status.Success) {
                    print.printf(&buf, "block {d}: {s}\r\n", .{lba, std.fmt.fmtSliceHexLower(&data)}, con_out);
                } else {
                    print.puts("Block IO read failed!\r\n", con_out);
                }
            }
        } else {
            print.puts("Block IO Protocol Handle NOT found!\r\n", con_out);
        }
    } else {
        print.puts("Block IO Protocol location failed!\r\n", con_out);
    }


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
    _ = boot_services.stall(1_000_000);
    print.puts(" => ", con_out);
    _ = boot_services.stall(1_000_000);
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
    while (true) {}
}
