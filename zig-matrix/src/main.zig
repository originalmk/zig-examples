const std = @import("std");

const MatrixOpError = error{
    IncompatibleSizes,
    OutOfBounds,
};

const Matrix = struct {
    allocator: std.mem.Allocator,
    numbers: []i64,
    dimensions: []const u64,

    pub fn init(allocator: std.mem.Allocator, dimensions: []const u64, init_numbers: []const i64) !Matrix {
        var size: u64 = 1;

        for (dimensions) |dim| {
            size *= dim;
        }

        var numbers = try allocator.alloc(i64, size);

        for (0.., init_numbers) |i, num| {
            numbers[i] = num;
        }

        return Matrix{
            .allocator = allocator,
            .numbers = numbers,
            .dimensions = dimensions,
        };
    }

    fn position_deep_to_flat(self: Matrix, position: []const u64) u64 {
        var flat_position: u64 = 0;
        var curr_volume: u64 = 1;

        for (0.., position) |i, pos| {
            flat_position += pos * curr_volume;
            curr_volume *= self.dimensions[i];
        }

        return flat_position;
    }

    pub fn get(self: Matrix, position: []const u64) !i64 {
        const flat_position = position_deep_to_flat(self, position);

        if (flat_position >= self.numbers.len) {
            return error.OutOfBounds;
        }

        return self.numbers[flat_position];
    }

    pub fn set(self: Matrix, position: []const u64, value: i64) !void {
        const flat_position = position_deep_to_flat(self, position);

        if (flat_position >= self.numbers.len) {
            return error.OutOfBounds;
        }

        self.numbers[flat_position] = value;
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

        var result: Matrix = try Matrix.init(
            allocator,
            self.dimensions,
            self.numbers,
        );

        for (other.numbers, 0..) |num, idx| {
            result.numbers[idx] += num;
        }

        return result;
    }

    pub fn sub(self: Matrix, allocator: std.mem.Allocator, other: Matrix) !Matrix {
        if (!std.mem.eql(u64, self.dimensions, other.dimensions)) {
            return error.IncompatibleSizes;
        }

        var result: Matrix = try Matrix.init(
            allocator,
            self.dimensions,
            self.numbers,
        );

        for (other.numbers, 0..) |num, idx| {
            result.numbers[idx] -= num;
        }

        return result;
    }

    pub fn neg(self: Matrix, allocator: std.mem.Allocator) !Matrix {
        var result: Matrix = try Matrix.init(
            allocator,
            self.dimensions,
            self.numbers,
        );

        for (0.., self.numbers) |idx, num| {
            result.numbers[idx] = -num;
        }

        return result;
    }

    pub fn deinit(self: Matrix) void {
        self.allocator.free(self.numbers);
    }
};

pub fn main() void {
    const help_text =
        \\Please use 'zig build test --summary all' to run tests.
        \\This example does not have any other runnable code.
        \\
    ;

    std.debug.print(help_text, .{});
}

test "matrix init" {
    const mat = try Matrix.init(std.testing.allocator, &.{ 5, 5 }, &.{});
    defer mat.deinit();

    try std.testing.expect(mat.numbers.len == 25);
}

test "matrix get 2 dim" {
    const mat = try Matrix.init(
        std.testing.allocator,
        &.{ 3, 3 },
        &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    );
    defer mat.deinit();

    try std.testing.expect(try mat.get(&.{ 0, 0 }) == 1);
    try std.testing.expect(try mat.get(&.{ 1, 0 }) == 2);
    try std.testing.expect(try mat.get(&.{ 2, 0 }) == 3);
    try std.testing.expect(try mat.get(&.{ 0, 1 }) == 4);
    try std.testing.expect(try mat.get(&.{ 1, 1 }) == 5);
    try std.testing.expect(try mat.get(&.{ 2, 1 }) == 6);
    try std.testing.expect(try mat.get(&.{ 0, 2 }) == 7);
    try std.testing.expect(try mat.get(&.{ 1, 2 }) == 8);
    try std.testing.expect(try mat.get(&.{ 2, 2 }) == 9);
}

test "matrix get 3 dim" {
    const mat = try Matrix.init(
        std.testing.allocator,
        &.{ 2, 2, 2 },
        &.{ 1, 2, 3, 4, 5, 6, 7, 8 },
    );
    defer mat.deinit();

    try std.testing.expect(try mat.get(&.{ 0, 0, 0 }) == 1);
    try std.testing.expect(try mat.get(&.{ 1, 0, 0 }) == 2);
    try std.testing.expect(try mat.get(&.{ 0, 1, 0 }) == 3);
    try std.testing.expect(try mat.get(&.{ 1, 1, 0 }) == 4);
    try std.testing.expect(try mat.get(&.{ 0, 0, 1 }) == 5);
    try std.testing.expect(try mat.get(&.{ 1, 0, 1 }) == 6);
    try std.testing.expect(try mat.get(&.{ 0, 1, 1 }) == 7);
    try std.testing.expect(try mat.get(&.{ 1, 1, 1 }) == 8);
}

test "matrix fill" {
    const mat = try Matrix.init(std.testing.allocator, &.{ 5, 5 }, &.{});
    defer mat.deinit();
    mat.fill(123);

    for (mat.numbers) |num| {
        try std.testing.expect(num == 123);
    }
}

test "matrix add" {
    const mat1 = try Matrix.init(std.testing.allocator, &.{ 2, 2 }, &.{});
    defer mat1.deinit();
    const mat2 = try Matrix.init(std.testing.allocator, &.{ 2, 2 }, &.{});
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
    const mat1 = try Matrix.init(std.testing.allocator, &.{ 2, 2 }, &.{});
    defer mat1.deinit();
    const mat2 = try Matrix.init(std.testing.allocator, &.{ 2, 2 }, &.{});
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

test "matrix neg" {
    const mat = try Matrix.init(
        std.testing.allocator,
        &.{ 3, 3 },
        &.{ 1, -2, 3, -4, 5, -6, 7, -8, 9 },
    );
    defer mat.deinit();

    const mat_neg = try Matrix.neg(mat, std.testing.allocator);
    defer mat_neg.deinit();

    const expected_numbers: []const i64 = &.{ -1, 2, -3, 4, -5, 6, -7, 8, -9 };

    try std.testing.expect(std.mem.eql(i64, mat_neg.numbers, expected_numbers));
}
