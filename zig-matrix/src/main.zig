const std = @import("std");

const MatrixOpError = error{
    IncompatibleDims,
    OutOfBounds,
};

const Matrix = struct {
    const RowIterator = struct {
        matrix: Matrix,
        rowIdx: u64,
        nextColIdx: u64,

        pub fn init(matrix: Matrix, rowIdx: u64) RowIterator {
            return RowIterator{
                .matrix = matrix,
                .rowIdx = rowIdx,
                .nextColIdx = 0,
            };
        }

        pub fn next(self: *RowIterator) ?i64 {
            if (self.nextColIdx == self.matrix.cols) {
                return null;
            }

            const nextValue = self.matrix.get(.{ self.rowIdx, self.nextColIdx }) catch unreachable;

            self.nextColIdx += 1;

            return nextValue;
        }
    };

    const ColIterator = struct {
        matrix: Matrix,
        colIdx: u64,
        nextRowIdx: u64,

        pub fn init(matrix: Matrix, rowIdx: u64) ColIterator {
            return ColIterator{
                .matrix = matrix,
                .colIdx = rowIdx,
                .nextRowIdx = 0,
            };
        }

        pub fn next(self: *ColIterator) ?i64 {
            if (self.nextRowIdx == self.matrix.rows) {
                return null;
            }

            const nextValue = self.matrix.get(.{ self.nextRowIdx, self.colIdx }) catch unreachable;

            self.nextRowIdx += 1;

            return nextValue;
        }
    };

    allocator: std.mem.Allocator,
    numbers: []i64,
    rows: u64,
    cols: u64,

    pub fn init(allocator: std.mem.Allocator, rows: u64, cols: u64, init_numbers: []const i64) !Matrix {
        var numbers = try allocator.alloc(i64, rows * cols);

        for (0.., init_numbers) |i, num| {
            numbers[i] = num;
        }

        return Matrix{
            .allocator = allocator,
            .numbers = numbers,
            .rows = rows,
            .cols = cols,
        };
    }

    fn position_deep_to_flat(self: Matrix, position: [2]u64) u64 {
        return position[0] * self.cols + position[1];
    }

    pub fn get(self: Matrix, position: [2]u64) !i64 {
        const flat_position = position_deep_to_flat(self, position);

        if (flat_position >= self.numbers.len) {
            return error.OutOfBounds;
        }

        return self.numbers[flat_position];
    }

    pub fn set(self: Matrix, position: [2]u64, value: i64) !void {
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
        if (self.rows != other.rows or self.cols != other.cols) {
            return error.IncompatibleSizes;
        }

        var result: Matrix = try Matrix.init(
            allocator,
            self.rows,
            self.cols,
            self.numbers,
        );

        for (0.., other.numbers) |idx, num| {
            result.numbers[idx] += num;
        }

        return result;
    }

    pub fn sub(self: Matrix, allocator: std.mem.Allocator, other: Matrix) !Matrix {
        if (self.rows != other.rows or self.cols != other.cols) {
            return error.IncompatibleSizes;
        }

        var result: Matrix = try Matrix.init(
            allocator,
            self.rows,
            self.cols,
            self.numbers,
        );

        for (0.., other.numbers) |idx, num| {
            result.numbers[idx] -= num;
        }

        return result;
    }

    pub fn neg(self: Matrix, allocator: std.mem.Allocator) !Matrix {
        var result: Matrix = try Matrix.init(
            allocator,
            self.rows,
            self.cols,
            self.numbers,
        );

        for (0.., self.numbers) |idx, num| {
            result.numbers[idx] = -num;
        }

        return result;
    }

    pub fn mul(self: Matrix, allocator: std.mem.Allocator, other: Matrix) !Matrix {
        if (self.cols != other.rows) {
            return error.IncompatibleDims;
        }

        var result: Matrix = try Matrix.init(
            allocator,
            self.rows,
            other.cols,
            &.{},
        );

        var currRow: u64 = 0;
        while (currRow < result.rows) : (currRow += 1) {
            var currCol: u64 = 0;
            while (currCol < result.cols) : (currCol += 1) {
                var currSum: i64 = 0;
                var rowIter = self.row(currRow);
                var colIter = other.col(currCol);

                while (rowIter.next()) |r| {
                    currSum += r * (colIter.next() orelse unreachable);
                }

                try result.set(.{ currRow, currCol }, currSum);
            }
        }

        return result;
    }

    pub fn row(self: Matrix, rowIdx: u64) RowIterator {
        return RowIterator.init(
            self,
            rowIdx,
        );
    }

    pub fn col(self: Matrix, colIdx: u64) ColIterator {
        return ColIterator.init(
            self,
            colIdx,
        );
    }

    pub fn eql(self: Matrix, other: Matrix) bool {
        const dimEqual = (self.cols == other.cols) and (self.rows == other.rows);
        const numEqual = std.mem.eql(i64, self.numbers, other.numbers);

        return dimEqual and numEqual;
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
    const mat = try Matrix.init(std.testing.allocator, 5, 5, &.{});
    defer mat.deinit();

    try std.testing.expect(mat.numbers.len == 25);
}

test "matrix get" {
    const mat = try Matrix.init(
        std.testing.allocator,
        3,
        3,
        &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    );
    defer mat.deinit();

    try std.testing.expect(try mat.get(.{ 0, 0 }) == 1);
    try std.testing.expect(try mat.get(.{ 0, 1 }) == 2);
    try std.testing.expect(try mat.get(.{ 0, 2 }) == 3);
    try std.testing.expect(try mat.get(.{ 1, 0 }) == 4);
    try std.testing.expect(try mat.get(.{ 1, 1 }) == 5);
    try std.testing.expect(try mat.get(.{ 1, 2 }) == 6);
    try std.testing.expect(try mat.get(.{ 2, 0 }) == 7);
    try std.testing.expect(try mat.get(.{ 2, 1 }) == 8);
    try std.testing.expect(try mat.get(.{ 2, 2 }) == 9);
}

test "matrix fill" {
    const mat = try Matrix.init(std.testing.allocator, 5, 5, &.{});
    defer mat.deinit();
    mat.fill(123);

    for (mat.numbers) |num| {
        try std.testing.expect(num == 123);
    }
}

test "matrix add" {
    const mat1 = try Matrix.init(std.testing.allocator, 2, 2, &.{});
    defer mat1.deinit();
    const mat2 = try Matrix.init(std.testing.allocator, 2, 2, &.{});
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
    const mat1 = try Matrix.init(std.testing.allocator, 2, 2, &.{});
    defer mat1.deinit();
    const mat2 = try Matrix.init(std.testing.allocator, 2, 2, &.{});
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
        3,
        3,
        &.{ 1, -2, 3, -4, 5, -6, 7, -8, 9 },
    );
    defer mat.deinit();

    const mat_neg = try Matrix.neg(mat, std.testing.allocator);
    defer mat_neg.deinit();

    const expected_numbers: []const i64 = &.{ -1, 2, -3, 4, -5, 6, -7, 8, -9 };

    try std.testing.expect(std.mem.eql(i64, mat_neg.numbers, expected_numbers));
}

test "matrix row iterator" {
    const mat = try Matrix.init(
        std.testing.allocator,
        3,
        3,
        &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    );
    defer mat.deinit();

    var row_iter = mat.row(0);

    try std.testing.expect(row_iter.next() == 1);
    try std.testing.expect(row_iter.next() == 2);
    try std.testing.expect(row_iter.next() == 3);
    try std.testing.expect(row_iter.next() == null);

    row_iter = mat.row(1);

    try std.testing.expect(row_iter.next() == 4);
    try std.testing.expect(row_iter.next() == 5);
    try std.testing.expect(row_iter.next() == 6);
    try std.testing.expect(row_iter.next() == null);

    row_iter = mat.row(2);

    try std.testing.expect(row_iter.next() == 7);
    try std.testing.expect(row_iter.next() == 8);
    try std.testing.expect(row_iter.next() == 9);
    try std.testing.expect(row_iter.next() == null);
}

test "matrix col iterator" {
    const mat = try Matrix.init(
        std.testing.allocator,
        3,
        3,
        &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    );
    defer mat.deinit();

    var col_iter = mat.col(0);

    try std.testing.expect(col_iter.next() == 1);
    try std.testing.expect(col_iter.next() == 4);
    try std.testing.expect(col_iter.next() == 7);
    try std.testing.expect(col_iter.next() == null);

    col_iter = mat.col(1);

    try std.testing.expect(col_iter.next() == 2);
    try std.testing.expect(col_iter.next() == 5);
    try std.testing.expect(col_iter.next() == 8);
    try std.testing.expect(col_iter.next() == null);

    col_iter = mat.col(2);

    try std.testing.expect(col_iter.next() == 3);
    try std.testing.expect(col_iter.next() == 6);
    try std.testing.expect(col_iter.next() == 9);
    try std.testing.expect(col_iter.next() == null);
}

test "matrix mul" {
    const mat1 = try Matrix.init(
        std.testing.allocator,
        2,
        3,
        &.{ 1, 2, 3, 4, 5, 6 },
    );
    defer mat1.deinit();

    const mat2 = try Matrix.init(
        std.testing.allocator,
        3,
        2,
        &.{ 1, 2, 3, 4, 5, 6 },
    );
    defer mat2.deinit();

    const mat3 = try mat1.mul(std.testing.allocator, mat2);
    defer mat3.deinit();

    try std.testing.expect(mat3.rows == 2);
    try std.testing.expect(mat3.cols == 2);
    try std.testing.expect(try mat3.get(.{ 0, 0 }) == 22);
    try std.testing.expect(try mat3.get(.{ 0, 1 }) == 28);
    try std.testing.expect(try mat3.get(.{ 1, 0 }) == 49);
    try std.testing.expect(try mat3.get(.{ 1, 1 }) == 64);
}

test "matrix eql" {
    const mat1 = try Matrix.init(
        std.testing.allocator,
        2,
        3,
        &.{ 1, 2, 3, 4, 5, 6 },
    );
    defer mat1.deinit();

    const mat2 = try Matrix.init(
        std.testing.allocator,
        2,
        3,
        &.{ 1, 2, 3, 4, 5, 6 },
    );
    defer mat2.deinit();

    const mat3 = try Matrix.init(
        std.testing.allocator,
        3,
        2,
        &.{ 1, 2, 3, 4, 5, 6 },
    );
    defer mat3.deinit();

    try std.testing.expect(mat1.eql(mat1));
    try std.testing.expect(mat2.eql(mat2));
    try std.testing.expect(mat3.eql(mat3));

    try std.testing.expect(mat1.eql(mat2));
    try std.testing.expect(mat2.eql(mat1));

    try std.testing.expect(!mat1.eql(mat3));
    try std.testing.expect(!mat2.eql(mat3));
    try std.testing.expect(!mat3.eql(mat1));
    try std.testing.expect(!mat3.eql(mat2));
}
