const print = @import("print.zig");
const bufPrintLen = print.bufPrintLen;

pub const Node = union(enum) {
    int: i64,
    float: f64,
    symbol: []const u8,
    string: []const u8,
    list: []const Node,
};

pub fn outputAst(buf: []u8, i: usize, node: *Node) usize {
    var offset: usize = i;
    switch(node.*) {
        .int => |int| offset += bufPrintLen(buf[offset..], "{d}", .{int}),
        .float => |float| offset += bufPrintLen(buf[offset..], "{d}", .{float}),
        .symbol => |symbol| offset += bufPrintLen(buf[offset..], "{s}", .{symbol}),
        .string => |string| offset += bufPrintLen(buf[offset..], "{s}", .{string}),
        .list => |list| {
            offset += bufPrintLen(buf[offset..], "(", .{});
            for(list) |n, o| {
                var vn = n;
                offset += outputAst(buf[(offset)..], i, &vn);
                if(o < (list.len - 1)) offset += bufPrintLen(buf[offset..], " ", .{});
            }
            offset += bufPrintLen(buf[(offset)..], ")", .{});
        }
    }
    return offset;
}
