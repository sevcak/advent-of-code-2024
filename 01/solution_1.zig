const std = @import("std");

fn readNumber(reader: anytype) !i32 {
    var num: i32 = 0;

    var reading_number = false;

    while (reader.readByte()) |c| {
        switch (c) {
            ' ', '\n' => {
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

fn readNumberPair(reader: anytype) ![2]i32 {
    const num_1 = try readNumber(reader);
    const num_2 = try readNumber(reader);

    return [2]i32{ num_1, num_2 };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var left_list = std.ArrayList(i32).init(allocator);
    defer left_list.deinit();
    var right_list = std.ArrayList(i32).init(allocator);
    defer right_list.deinit();

    const file = try std.fs.cwd().openFile("./input_1.txt", .{});
    defer file.close();
    const reader = file.reader();

    while (readNumberPair(reader)) |pair| {
        try left_list.append(pair[0]);
        try right_list.append(pair[1]);
    } else |err| {
        if (err != error.EndOfStream) {
            std.debug.print("An error ocurred while reading the file.\n", .{});
            return;
        }
    }

    std.mem.sort(i32, left_list.items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, right_list.items, {}, comptime std.sort.asc(i32));

    var total_distance: u32 = 0;

    for (left_list.items, right_list.items) |left_num, right_num| {
        total_distance += @abs(left_num - right_num);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Total distance: {}\n", .{total_distance});
}
