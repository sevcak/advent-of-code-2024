const std = @import("std");

fn readNumber(reader: anytype) !struct { num: u32, delim: u8 } {
    var num: u32 = 0;
    var reading_num = false;
    while (reader.readByte()) |c| {
        if (c < '0' or c > '9') {
            if (!reading_num) {
                return error.NoNumber;
            }

            return .{ .num = num, .delim = c };
        }
        reading_num = true;
        num = num * 10 + (c - '0');
    } else |err| {
        return err;
    }

    return error.NoNumber;
}

fn readUntilSubstr(reader: anytype, match: []const u8) !void {
    var cur_match_idx: u8 = 0;

    while (reader.readByte()) |c| {
        if (c != match[cur_match_idx]) {
            cur_match_idx = 0;
        } else {
            cur_match_idx += 1;

            if (cur_match_idx == match.len) {
                return;
            }
        }
    } else |err| {
        return err;
    }
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./input.txt", .{});
    defer file.close();
    const reader = file.reader();

    var result: u32 = 0;

    while (readUntilSubstr(reader, "mul(")) {
        const num_a_parsed = readNumber(reader) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        if (num_a_parsed.delim != ',') continue;

        const num_b_parsed = readNumber(reader) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        if (num_b_parsed.delim != ')') continue;

        // std.debug.print("mul({},{})\n", .{ num_a_parsed.num, num_b_parsed.num });

        result += num_a_parsed.num * num_b_parsed.num;
    } else |err| {
        if (err != error.EndOfStream) {
            std.debug.print("An error ocurred while reading the file.\n", .{});
            return err;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Multiplication results sum: {}\n", .{result});
}
