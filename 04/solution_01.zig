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

fn getXmasStartCount(matrix: ArrayList(ArrayList(u8)), width: usize, height: usize, row_i: usize, col_i: usize) u8 {
    const word = "XMAS";

    if (row_i >= height or col_i >= width) {
        return 0;
    }
    if (matrix.items[row_i].items[col_i] != word[0]) {
        return 0;
    }

    var count: u8 = 0;
    const offsets = [_][2]i2{ .{ 1, 0 }, .{ 1, 1 }, .{ 0, 1 }, .{ -1, 1 }, .{ -1, 0 }, .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 } };

    for (offsets) |offset| {
        const dx = offset[0];
        const dy = offset[1];
        var x = col_i;
        var y = row_i;

        for (1..word.len) |char_i| {
            if (dx == 1) {
                if (x == width - 1) {
                    break;
                }
                x += 1;
            } else if (dx == -1) {
                if (x == 0) {
                    break;
                }
                x -= 1;
            }
            if (dy == 1) {
                if (y == height - 1) {
                    break;
                }
                y += 1;
            } else if (dy == -1) {
                if (y == 0) {
                    break;
                }
                y -= 1;
            }

            if (matrix.items[y].items[x] != word[char_i]) {
                break;
            }

            if (char_i == word.len - 1) {
                // std.debug.print("Found XMAS at: [{}, {}] -> [{}, {}]\n", .{ col_i, row_i, x, y });
                count += 1;
            }
        }
    }

    return count;
}

fn getXmasCount(matrix: ArrayList(ArrayList(u8))) u32 {
    const h: usize = matrix.items.len;
    if (h == 0) {
        return 0;
    }
    const w: usize = matrix.items[0].items.len;
    var count: u32 = 0;

    for (matrix.items, 0..) |row, row_i| {
        for (row.items, 0..) |_, col_i| {
            count += getXmasStartCount(matrix, w, h, row_i, col_i);
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
