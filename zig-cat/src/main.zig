const std = @import("std");

pub fn main() !void {
    if (std.os.argv.len > 1) {
        handle_file_input();
    } else {
        handle_stdin_input();
    }
}

pub fn handle_file_input() void {
    for (std.os.argv[1..]) |file_path_sent| {
        const file_path = std.mem.span(file_path_sent);
        const file = std.fs.cwd().openFile(
            file_path,
            .{ .mode = .read_only },
        ) catch |err| {
            std.debug.print("error occurred while opening file: {s}\n", .{@errorName(err)});
            return;
        };
        defer file.close();

        print_from_stream(file.reader().any()) catch continue;
    }
}

pub fn handle_stdin_input() void {
    print_from_stream(std.io.getStdIn().reader().any()) catch return;
}

pub fn print_from_stream(stream: std.io.AnyReader) !void {
    while (true) {
        var line = std.ArrayList(u8).init(std.heap.page_allocator);
        defer line.deinit();

        try stream.streamUntilDelimiter(
            line.writer(),
            '\n',
            null,
        );

        std.debug.print("{s}\n", .{line.items});
    }
}
