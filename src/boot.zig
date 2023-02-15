const std = @import("std");
const uefi = std.os.uefi;
const unicode = std.unicode;
const print = @import("print.zig");
const ast = @import("ast.zig");
const Node = ast.Node;

var add = [_]Node{ 
    Node{ .symbol = "+"}, 
    Node{ .int = 10}, 
    Node{ .int = 32 }, 
};
var spec = Node{ .list = &add };

pub fn main() void {
    const con_out = uefi.system_table.con_out.?;
    _ = con_out.reset(false);
    _ = con_out.outputString(print.L("LunaOS\r\n"));
    var buf: [256]u8 = undefined;
    const len = ast.outputAst(&buf, 0, &spec);
    print.puts(buf[0..len], con_out);

    const boot_services = uefi.system_table.boot_services.?;
    _ = boot_services.setWatchdogTimer(0, 0, 0, null);
    //_ = boot_services.stall(5_000_000);
    while (true) {}
}
