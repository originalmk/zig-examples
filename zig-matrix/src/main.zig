const std = @import("std");

const MatrixOpError = error{
    IncompatibleSizes,
};

const Matrix = struct {
    allocator: std.mem.Allocator,
    numbers: []i64,
    dimensions: []const u64,

    pub fn init(allocator: std.mem.Allocator, dimensions: []const u64) !Matrix {
        var size: u64 = 1;

        for (dimensions) |dim| {
            size *= dim;
        }

        return Matrix{
            .allocator = allocator,
            .numbers = try allocator.alloc(i64, size),
            .dimensions = dimensions,
        };
    }

    pub fn fill(self: Matrix, number: i64) void {
        var i: u64 = 0;
        while (i < self.numbers.len) {
            self.numbers[i] = number;
            i += 1;
        }
    }

    pub fn add(self: Matrix, allocator: std.mem.Allocator, other: Matrix) !Matrix {
        if (!std.mem.eql(u64, self.dimensions, other.dimensions)) {
            return error.IncompatibleSizes;
        }

        var result: Matrix = try Matrix.init(allocator, self.dimensions);
        result.fill(0);

        for (self.numbers, 0..) |num, idx| {
            result.numbers[idx] += num;
        }

        for (other.numbers, 0..) |num, idx| {
            result.numbers[idx] += num;
        }

        return result;
    }

    pub fn sub(self: Matrix, allocator: std.mem.Allocator, other: Matrix) !Matrix {
        if (!std.mem.eql(u64, self.dimensions, other.dimensions)) {
            return error.IncompatibleSizes;
        }

        var result: Matrix = try Matrix.init(allocator, self.dimensions);
        result.fill(0);

        for (self.numbers, 0..) |num, idx| {
            result.numbers[idx] += num;
        }

        for (other.numbers, 0..) |num, idx| {
            result.numbers[idx] -= num;
        }

        return result;
    }

    pub fn deinit(self: Matrix) void {
        self.allocator.free(self.numbers);
    }
};

pub fn main() void {
    std.debug.print("Please use 'zig build test --summary all' to run tests. This example does not have any other runnable code.\n", .{});
}

test "matrix init" {
    const mat = try Matrix.init(std.testing.allocator, &[_]u64{ 5, 5 });
    defer mat.deinit();

    try std.testing.expect(mat.numbers.len == 25);
}

test "matrix fill" {
    const mat = try Matrix.init(std.testing.allocator, &[_]u64{ 5, 5 });
    defer mat.deinit();
    mat.fill(123);

    for (mat.numbers) |num| {
        try std.testing.expect(num == 123);
    }
}

test "matrix add" {
    const mat1 = try Matrix.init(std.testing.allocator, &[_]u64{ 2, 2 });
    defer mat1.deinit();
    const mat2 = try Matrix.init(std.testing.allocator, &[_]u64{ 2, 2 });
    defer mat2.deinit();

    mat1.fill(1);
    mat2.fill(2);

    const mat3 = try mat1.add(std.testing.allocator, mat2);
    defer mat3.deinit();

    try std.testing.expect(mat3.numbers[0] == 3);
    try std.testing.expect(mat3.numbers[1] == 3);
    try std.testing.expect(mat3.numbers[2] == 3);
    try std.testing.expect(mat3.numbers[3] == 3);
}

test "matrix sub" {
    const mat1 = try Matrix.init(std.testing.allocator, &[_]u64{ 2, 2 });
    defer mat1.deinit();
    const mat2 = try Matrix.init(std.testing.allocator, &[_]u64{ 2, 2 });
    defer mat2.deinit();

    mat1.fill(1);
    mat2.fill(2);

    const mat3 = try mat1.sub(std.testing.allocator, mat2);
    defer mat3.deinit();

    try std.testing.expect(mat3.numbers[0] == -1);
    try std.testing.expect(mat3.numbers[1] == -1);
    try std.testing.expect(mat3.numbers[2] == -1);
    try std.testing.expect(mat3.numbers[3] == -1);
}
