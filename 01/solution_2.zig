const std = @import("std");

fn readNumber(reader: anytype) !u32 {
    var num: u32 = 0;

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

fn readNumberPair(reader: anytype) ![2]u32 {
    const num_1 = try readNumber(reader);
    const num_2 = try readNumber(reader);

    return [2]u32{ num_1, num_2 };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var left_list = std.ArrayList(u32).init(allocator);
    defer left_list.deinit();
    var right_counts = std.AutoHashMap(u32, u32).init(allocator);
    defer right_counts.deinit();

    const file = try std.fs.cwd().openFile("./input_1.txt", .{});
    defer file.close();
    const reader = file.reader();

    while (readNumberPair(reader)) |pair| {
        try left_list.append(pair[0]);

        const gop = try right_counts.getOrPut(pair[1]);
        gop.value_ptr.* = if (!gop.found_existing) 1 else gop.value_ptr.* + 1;
    } else |err| {
        if (err != error.EndOfStream) {
            std.debug.print("An error ocurred while reading the file.\n", .{});
            return;
        }
    }

    var total_similarity: u32 = 0;

    for (left_list.items) |left_num| {
        const get = right_counts.get(left_num);
        total_similarity += left_num * (if (get) |count| count else 0);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Similarity score: {}\n", .{total_similarity});
}
