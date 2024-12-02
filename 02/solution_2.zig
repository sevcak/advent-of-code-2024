const std = @import("std");

fn readNumberLine(reader: anytype, alloc: std.mem.Allocator) ![]i32 {
    var nums = std.ArrayList(i32).init(alloc);
    defer nums.deinit();

    var num: i32 = 0;
    var reading_num = false;
    while (reader.readByte()) |c| {
        switch (c) {
            ' ' => {
                if (reading_num) {
                    try nums.append(num);
                    num = 0;
                    reading_num = false;
                }
            },
            '\n' => {
                if (reading_num) {
                    try nums.append(num);
                }

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

fn removeElement(alloc: std.mem.Allocator, comptime T: type, arr: []const T, remove_idx: usize) ![]T {
    if (remove_idx >= arr.len) {
        return error.IndexOutOfBounds;
    }

    var new_arr = try alloc.alloc(T, arr.len - 1);
    errdefer alloc.free(new_arr);

    @memcpy(new_arr[0..remove_idx], arr[0..remove_idx]);
    @memcpy(new_arr[remove_idx..], arr[remove_idx + 1 ..]);

    return new_arr;
}

fn isSafe(nums: []i32, removable: u8, alloc: std.mem.Allocator) !bool {
    var is_inc = true;
    var is_dec = true;

    var i: u8 = 1;
    while (i < nums.len) : (i += 1) {
        if (is_inc and nums[i] <= nums[i - 1]) {
            is_inc = false;
        }
        if (is_dec and nums[i] >= nums[i - 1]) {
            is_dec = false;
        }

        if ((!is_inc and !is_dec) or @abs(nums[i] - nums[i - 1]) > 3) {
            if (removable == 0) {
                return false;
            }

            var j: u8 = 0;
            while (j <= i) : (j += 1) {
                const removed = try removeElement(alloc, i32, nums, j);
                defer alloc.free(removed);
                if (try isSafe(removed, removable - 1, alloc)) {
                    return true;
                }
            }

            return false;
        }
    }

    return true;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./input_1.txt", .{});
    defer file.close();
    const reader = file.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var safe_count: u16 = 0;
    var line_i: u16 = 0;

    while (readNumberLine(reader, allocator)) |nums| {
        defer allocator.free(nums);

        line_i += 1;

        if (try isSafe(nums, 1, allocator)) {
            safe_count += 1;
        }
    } else |err| {
        if (err != error.EndOfStream) {
            std.debug.print("An error ocurred while reading the file.\n", .{});
            return;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Safe reports: {}\n", .{safe_count});
}
