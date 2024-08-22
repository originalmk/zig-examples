const std = @import("std");
const c = @cImport({
    @cInclude("lib.h");
});

pub fn main() void {
    std.debug.print("Hello!\n", .{});
    std.debug.print("{}\n", .{c.add(3, 5)});
}
