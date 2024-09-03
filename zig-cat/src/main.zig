const std = @import("std");

pub fn main() !void {
    for (std.os.argv[1..]) |file_path_sent| {
        const file_path = std.mem.span(file_path_sent);
        const file = std.fs.openFileAbsolute(
            file_path,
            .{ .mode = .read_only },
        ) catch |err| {
            std.debug.print("error occurred while opening file: {s}\n", .{@errorName(err)});
            return;
        };
        defer file.close();

        while (true) {
            var ar = std.ArrayList(u8).init(std.heap.page_allocator);
            defer ar.deinit();

            file.reader().streamUntilDelimiter(
                ar.writer(),
                '\n',
                null,
            ) catch break;

            std.debug.print("{s}\n", .{ar.items});
        }
    }
}
