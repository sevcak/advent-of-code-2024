const std = @import("std");

const Operation = enum { mul, do, dont, nop };

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

fn readUntilOp(first_c: u8, reader: anytype) !Operation {
    var match: []const u8 = undefined;
    match = "mul(";
    var cur_match_idx: u8 = 0;
    var matched_op = Operation.nop;

    if (first_c == 'm') {
        match = "mul(";
        cur_match_idx = 1;
        matched_op = Operation.mul;
    } else if (first_c == 'd') {
        match = "do";
        cur_match_idx = 1;
        matched_op = Operation.nop;
    }

    while (reader.readByte()) |c| {
        if (cur_match_idx == 0) {
            switch (c) {
                'm' => {
                    match = "mul(";
                    matched_op = Operation.mul;
                },
                'd' => {
                    match = "do";
                    matched_op = Operation.nop;
                },
                else => {
                    matched_op = Operation.nop;
                    continue;
                },
            }
        } else if (cur_match_idx == 2 and matched_op == Operation.nop) {
            if (c == '(') {
                match = "do()";
                matched_op = Operation.do;
            } else {
                match = "don't()";
                matched_op = Operation.dont;
            }
        }

        if (c != match[cur_match_idx]) {
            switch (c) {
                'm' => {
                    match = "mul(";
                    matched_op = Operation.mul;
                    cur_match_idx = 1;
                },
                'd' => {
                    match = "do";
                    matched_op = Operation.nop;
                    cur_match_idx = 1;
                },
                else => {
                    matched_op = Operation.nop;
                    cur_match_idx = 0;
                },
            }
        } else {
            cur_match_idx += 1;

            if (cur_match_idx == match.len) {
                if (matched_op != Operation.nop) {
                    return matched_op;
                }
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
    var mul_enabled = true;
    var op_prefix: u8 = ' ';

    while (readUntilOp(op_prefix, reader)) |op| {
        switch (op) {
            Operation.mul => {
                if (!mul_enabled) continue;

                const num_a_parsed = readNumber(reader) catch |err| switch (err) {
                    error.EndOfStream => break,
                    else => return err,
                };
                if (num_a_parsed.delim != ',') {
                    op_prefix = num_a_parsed.delim;
                    continue;
                }

                const num_b_parsed = readNumber(reader) catch |err| switch (err) {
                    error.EndOfStream => break,
                    else => return err,
                };
                if (num_b_parsed.delim != ')') {
                    op_prefix = num_b_parsed.delim;
                    continue;
                }

                op_prefix = ' ';

                //std.debug.print("mul({},{})\n", .{ num_a_parsed.num, num_b_parsed.num });

                result += num_a_parsed.num * num_b_parsed.num;
            },
            Operation.do => {
                mul_enabled = true;
                // std.debug.print("do()\n", .{});
            },
            Operation.dont => {
                mul_enabled = false;
                // std.debug.print("don't()\n", .{});
            },
            Operation.nop => {},
        }

        op_prefix = ' ';
    } else |err| {
        if (err != error.EndOfStream) {
            std.debug.print("An error ocurred while reading the file.\n", .{});
            return err;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Multiplication results sum: {}\n", .{result});
}
