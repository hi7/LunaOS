const std = @import("std");

pub fn add(a: usize, b: usize) usize {
    return asm volatile (
        \\addq %rdi, %rax
        : [ret] "={rax}" (-> usize)
        : [a] "{rax}" (a),
          [b] "{rdi}" (b),
        : "rcx", "r11"
    );
}

test "add" {
    try std.testing.expectEqual(@as(usize, 99999999), add(12345678, 87654321));
}