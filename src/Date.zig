const std = @import("std");

const Date = @This();

year: u16,
month: u4,
day: u5,

pub fn compare(self: Date, other: Date) std.math.Order {
    if (self.year != other.year) return if (self.year < other.year) std.math.Order.lt else std.math.Order.gt;
    if (self.month != other.month) return if (self.month < other.month) std.math.Order.lt else std.math.Order.gt;
    if (self.day != other.day) return if (self.day < other.day) std.math.Order.lt else std.math.Order.gt;
    return std.math.Order.eq;
}

pub fn jsonStringify(self: @This(), jws: anytype) !void {
    try jws.print("\"{d:0>4}-{d:0>2}-{d:0>2}\"", .{ self.year, self.month, self.day });
}

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !Date {
    switch (try source.nextAllocMax(allocator, options.allocate.?, options.max_value_len.?)) {
        inline .string, .allocated_string => |slice| return .{
            .year = @intCast(try std.fmt.parseInt(u16, slice[0..4], 10)),
            .month = @intCast(try std.fmt.parseInt(u8, slice[5..7], 10)),
            .day = @intCast(try std.fmt.parseInt(u8, slice[8..10], 10)),
        },
        else => unreachable,
    }
}
