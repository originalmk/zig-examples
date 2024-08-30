const std = @import("std");

const AddNumbersError = error{
    InequalLengths,
    GuardOverflow,
};

// This functions performs saturated addition of two u8 (unsigned 8-bit integer) slices,
// but if any addition result is more than guard then it returns GuardOverflow error instead.
pub fn numbers_magic(allocator: std.mem.Allocator, a: []const u8, b: []const u8, guard: u8) ![]u8 {
    if (a.len != b.len) {
        return error.InequalLengths;
    }

    var result = try allocator.alloc(u8, a.len);
    // errdefer is called only when error is returned, so when there is no error normal result will
    // be returned to the caller (it should not be deallocated in every case, because it would result
    // in segmentation fault)
    errdefer allocator.free(result);

    for (0.., result) |idx, _| {
        // Saturated addition to avoid integer overflow panic.
        result[idx] = a[idx] +| b[idx];

        if (result[idx] > guard) {
            return error.GuardOverflow;
        }
    }

    return result;
}

pub fn main() !void {
    std.debug.print(
        "This example does not offer runnable code other than tests. Use zig build test to run them :)\n",
        .{},
    );
}

// This numbers_magic call will not generate any error, so try is used.
// The result needs to be freed, because there was no error.
test "numers magic no error, no memory leak" {
    const result = try numbers_magic(
        std.testing.allocator,
        &.{ 1, 2, 3, 4, 5, 6 },
        &.{ 2, 1, 3, 7, 4, 2 },
        50,
    );
    defer std.testing.allocator.free(result);
}

// Numbers magic call is expected to return error (40 + 17 > 50), no deallocation is needed here.
// and it does not result in any memory leak, because of errdefer inside numbers_magic,
// which cleans up in that case.
test "numbers magic error, no memory leak" {
    const result = numbers_magic(
        std.testing.allocator,
        &.{ 10, 20, 30, 40, 45, 43 },
        &.{ 12, 11, 13, 17, 14, 12 },
        50,
    );

    try std.testing.expect(result == error.GuardOverflow);
}

// Just to show that there will be memory leak if function succeeded (no error returned).
// Errdefer inside numbers_magic won't clean up in this case, so without using
// std.testing.allocator.free(...) this will leak memory.
// This test will fail, there should be information about this in output e.g. "1 leaked"
test "numbers magic no error, memory leak" {
    _ = try numbers_magic(
        std.testing.allocator,
        &.{ 1, 2, 3, 4, 5, 6 },
        &.{ 2, 1, 3, 7, 4, 2 },
        50,
    );
}
