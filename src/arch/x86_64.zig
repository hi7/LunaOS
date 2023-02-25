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
