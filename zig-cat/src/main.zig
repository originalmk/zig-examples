const std = @import("std");

pub fn main() !void {
    for (std.os.argv[1..]) |file_path_sent| {
        const file_path = std.mem.span(file_path_sent);
        const file = try std.fs.openFileAbsolute(
            file_path,
            .{ .mode = .read_only },
        );
        defer file.close();

        while (true) {
            const rw_result = file.reader().streamUntilDelimiter(
                std.io.getStdOut().writer(),
                '\n',
                null,
            );

            if (rw_result) |_| {} else |_| {
                break;
            }

            std.debug.print("\n", .{});
        }
    }
}
