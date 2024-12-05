const std = @import("std");

fn readNumberLine(reader: anytype, alloc: std.mem.Allocator, delim: u8) ![]u32 {
    var nums = std.ArrayList(u32).init(alloc);
    defer nums.deinit();

    var num: u32 = 0;
    var reading_num = false;
    while (reader.readByte()) |c| {
        if (c == delim and reading_num) {
            try nums.append(num);
            num = 0;
            reading_num = false;
        } else switch (c) {
            '\n' => {
                if (!reading_num) {
                    return error.EmptyLine;
                }
                try nums.append(num);

                return nums.toOwnedSlice();
            },
            '0'...'9' => {
                num = num * 10 + c - '0';
                reading_num = true;
            },
            else => {
                return error.InvalidCharacter;
            },
        }
    } else |err| {
        if (err != error.EndOfStream or nums.items.len == 0) {
            return err;
        }

        if (reading_num) {
            try nums.append(num);
        }
    }

    return nums.toOwnedSlice();
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./input.txt", .{});
    defer file.close();
    const reader = file.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var num_preds = std.AutoHashMap(u32, std.ArrayList(u32)).init(alloc);
    defer {
        var iter = num_preds.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        num_preds.deinit();
    }

    // Read rules
    while (readNumberLine(reader, alloc, '|')) |nums| {
        defer alloc.free(nums);

        const gop = try num_preds.getOrPut(nums[1]);
        if (!gop.found_existing) {
            gop.value_ptr.* = std.ArrayList(u32).init(alloc);
        }
        try gop.value_ptr.*.append(nums[0]);
    } else |err| {
        if (err != error.EndOfStream and err != error.EmptyLine) {
            std.debug.print("An error ocurred while reading the file.\n", .{});
            return err;
        }
    }

    var sum: u32 = 0;

    // Read updates
    while (readNumberLine(reader, alloc, ',')) |nums| {
        defer alloc.free(nums);

        var is_correct = true;
        var bad_nums = std.ArrayList(u32).init(alloc);
        defer bad_nums.deinit();

        for (nums) |num| {
            for (bad_nums.items) |bad_num| {
                if (bad_num == num) {
                    is_correct = false;
                    break;
                }
            }
            if (!is_correct) {
                break;
            }

            if (num_preds.get(num)) |preds| {
                for (preds.items) |pred| {
                    try bad_nums.append(pred);
                }
            }
        }

        if (is_correct) {
            sum += nums[nums.len / 2];
        }
    } else |err| {
        if (err != error.EndOfStream and err != error.EmptyLine) {
            std.debug.print("An error ocurred while reading the file.\n", .{});
            return err;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Answer: {}\n", .{sum});
}
