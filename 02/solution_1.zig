const std = @import("std");

fn readNumber(reader: anytype, new_line_ptr: *bool) !i32 {
    var num: i32 = 0;

    var reading_number = false;

    while (reader.readByte()) |c| {
        switch (c) {
            ' ', '\n' => {
                if (c == '\n') {
                    new_line_ptr.* = true;
                }
                if (reading_number) {
                    return num;
                }
            },
            else => {
                num = num * 10 + c - '0';
                reading_number = true;
            },
        }
    } else |err| {
        return err;
    }

    return num;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./input_1.txt", .{});
    // const file = try std.fs.cwd().openFile("./input_text.txt", .{});
    defer file.close();
    const reader = file.reader();

    var safe_count: u16 = 0;

    var new_line = false;
    var is_dec = true;
    var is_inc = true;
    var prev_num: i32 = undefined;
    var first_num = true;
    var is_safe = true;

    while (readNumber(reader, &new_line)) |num| {
        if (!first_num) {
            if (is_inc and num <= prev_num) {
                is_inc = false;
            }
            if (is_dec and num >= prev_num) {
                is_dec = false;
            }

            if ((!is_inc and !is_dec) or @abs(num - prev_num) > 3) {
                is_safe = false;
                try reader.skipUntilDelimiterOrEof('\n');
                new_line = true;
            }
        }

        prev_num = num;
        first_num = false;

        if (new_line) {
            if (is_safe) {
                safe_count += 1;
            }

            new_line = false;
            is_dec = true;
            is_inc = true;
            first_num = true;
            is_safe = true;
        }
    } else |err| {
        if (err != error.EndOfStream) {
            std.debug.print("An error ocurred while reading the file.\n", .{});
            return;
        }

        if (is_safe and !first_num) {
            safe_count += 1;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Safe reports: {}\n", .{safe_count});
}
