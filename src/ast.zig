const print = @import("print.zig");
const bufPrintLen = print.bufPrintLen;

// immutable
pub const Node = union(enum) {
    boolean: bool,
    int: i64,
    float: f64,
    string: []const u8,
    symbol: []const u8,
    list: []const Node,
};

pub const NodeMutable = union(enum) {
    boolean: bool,
    int: i64,
    float: f64,
    string: []const u8,
    symbol: []const u8,
    list: []const NodeMutable,
};

pub fn outputAst(buf: []u8, i: usize, node: *Node) error{NoSpaceLeft}!usize {
    var offset: usize = i;
    switch(node.*) {
        .boolean => |boolean| offset += try bufPrintLen(buf[offset..], "{s}", .{ if(boolean) "#t" else "#f"}),
        .int => |int| offset += try bufPrintLen(buf[offset..], "{d}", .{int}),
        .float => |float| offset += try bufPrintLen(buf[offset..], "{d}", .{float}),
        .string => |string| offset += try bufPrintLen(buf[offset..], "{s}", .{string}),
        .symbol => |symbol| offset += try bufPrintLen(buf[offset..], "{s}", .{symbol}),
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
