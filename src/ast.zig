const print = @import("print.zig");
const bufPrintLen = print.bufPrintLen;

// immutable
pub const Node = union(enum) {
    boolean: bool,
    int: i64,
    float: f64,
    symbol: []const u8,
    string: []const u8,
    list: []const Node,
};

pub fn outputAst(buf: []u8, i: usize, node: *Node) error{NoSpaceLeft}!usize {
    var offset: usize = i;
    switch(node.*) {
        .boolean => |boolean| offset += try bufPrintLen(buf[offset..], "{s}", .{ if(boolean) "#t" else "#f"}),
        .int => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .float => |float| offset += try bufPrintLen(buf[offset..], "{d}", .{float}),
        .symbol => |symbol| offset += try bufPrintLen(buf[offset..], "{s}", .{symbol}),
        .string => |string| offset += try bufPrintLen(buf[offset..], "{s}", .{string}),
        .list => |list| {
            offset += try bufPrintLen(buf[offset..], "(", .{});
            for(list) |n, o| {
                var vn = n;
                offset += try outputAst(buf[(offset)..], i, &vn);
                if(o < (list.len - 1)) offset += try bufPrintLen(buf[offset..], " ", .{});
            }
            offset += try bufPrintLen(buf[(offset)..], ")", .{});
        }
    }
    return offset;
}
