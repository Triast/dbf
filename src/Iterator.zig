const std = @import("std");
const Table = @import("Table.zig");
const Row = @import("Row.zig");
const Allocator = std.mem.Allocator;
const Reader = std.Io.Reader;

const Iterator = @This();

table: *Table,
buffer: []u8 = undefined,

index: u32 = 0,

pub fn init(allocator: Allocator, table: *Table) Allocator.Error!Iterator {
    const buf = try allocator.alloc(u8, table.length_of_one_data_record);

    return .{
        .table = table,
        .buffer = buf,
    };
}

pub fn deinit(self: Iterator, allocator: Allocator) void {
    allocator.free(self.buffer);
}

pub fn next(self: *Iterator) Reader.Error!?Row {
    if (self.index >= self.table.number_of_records) return null;

    self.table.reader.readSliceAll(self.buffer) catch |err| switch (err) {
        error.EndOfStream => return null,
        error.ReadFailed => return err,
    };

    self.index += 1;

    return .{
        .table = self.table,
        .iterator = self,
    };
}
