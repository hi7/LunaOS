#!/bin/sh
zig test src/ast.zig;
zig test src/boot.zig;
zig test src/env.zig;
zig test src/eval.zig;
zig test src/print.zig;