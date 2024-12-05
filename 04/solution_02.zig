const std = @import("std");
const ArrayList = std.ArrayList;

fn readLine(reader: anytype, buffer: *ArrayList(u8)) ![]u8 {
    buffer.clearRetainingCapacity();

    while (reader.readByte()) |c| {
        if (c == '\n') {
            return buffer.items;
        }

        try buffer.append(c);
    } else |err| {
        if (err != error.EndOfStream) {
            return err;
        }

        if (buffer.items.len > 0) {
            return buffer.items;
        }

        return err;
    }
}

fn readFileTo2DList(alloc: std.mem.Allocator, filepath: []const u8) !ArrayList(ArrayList(u8)) {
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var rows = ArrayList(ArrayList(u8)).init(alloc);
    errdefer {
        for (rows.items) |*row| {
            row.deinit();
        }

        rows.deinit();
    }

    var line_buf = ArrayList(u8).init(alloc);
    defer line_buf.deinit();

    while (readLine(reader, &line_buf)) |line| {
        // std.debug.print("Read line: {s}\n", .{line});
        var row = ArrayList(u8).init(alloc);
        try row.appendSlice(line);
        try rows.append(row);
    } else |err| {
        if (err != error.EndOfStream) {
            return err;
        }
    }

    return rows;
}

fn getXmasCount(matrix: ArrayList(ArrayList(u8))) u32 {
    const h: usize = matrix.items.len;
    if (h == 0) {
        return 0;
    }
    const w: usize = matrix.items[0].items.len;
    var count: u32 = 0;

    const word = "MAS";
    const offsets = [_][2]i2{ .{ 1, 1 }, .{ -1, 1 } };

    for (0..h - word.len + 1) |row| {
        for (0..w - word.len + 1) |col| {
            const start_xs: [2]usize = .{ col, col + word.len - 1 };
            var diagonal_matches: u2 = 0;

            for (start_xs, offsets) |start_x, offset| {
                var in_order = true;
                var reversed = true;
                var i: usize = 0;
                var x = start_x;
                var y = row;

                while (i < word.len and (in_order or reversed)) : (i += 1) {
                    if (in_order and matrix.items[y].items[x] != word[i]) {
                        in_order = false;
                    }
                    if (reversed and matrix.items[y].items[x] != word[word.len - 1 - i]) {
                        reversed = false;
                    }

                    if (i < word.len - 1) {
                        if (offset[0] == -1) {
                            x -= 1;
                        } else if (offset[0] == 1) {
                            x += 1;
                        }
                        if (offset[1] == -1) {
                            y -= 1;
                        } else if (offset[1] == 1) {
                            y += 1;
                        }
                    }
                }

                if (in_order or reversed) {
                    diagonal_matches += 1;
                }
            }

            if (diagonal_matches == 2) {
                // std.debug.print("Found X at: [{}, {}]\n", .{ col, row });
                count += 1;
            }
        }
    }

    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const matrix = try readFileTo2DList(alloc, "./input.txt");
    // const matrix = try readFileTo2DList(alloc, "./input_small.txt");
    defer {
        for (matrix.items) |*row| {
            row.deinit();
        }
        matrix.deinit();
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("XMAS count: {}.\n", .{getXmasCount(matrix)});
}
