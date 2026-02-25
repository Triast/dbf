const std = @import("std");
const Date = @import("Date.zig");
const Iterator = @import("Iterator.zig");
const StructIterator = @import("iterators.zig").StructIterator;
const Allocator = std.mem.Allocator;
const Reader = std.Io.Reader;

const Table = @This();

pub const Field = struct {
    const Type = enum(u8) {
        blob = 'W',
        character = 'C',
        currency = 'Y',
        double = 'B',
        date = 'D',
        datetime = 'T',
        float = 'F',
        general = 'G',
        integer = 'I',
        logical = 'L',
        memo = 'M',
        numeric = 'N',
        picture = 'P',
        varbinary = 'Q',
        varchar = 'V',
        null = '0',
    };

    name: []const u8,
    type: Type,
    displacement_in_record: u32,
    length: u8,
    number_of_decimal_places: u8,
};

const Options = struct {
    ignore_deleted: bool = true,
    trim_strings: bool = true,
};

last_update: Date,
number_of_records: u32,
position_of_first_data_record: u16,
length_of_one_data_record: u16,
fields: std.StringArrayHashMap(Field),
options: Options,

reader: *Reader,

const InitError = Allocator.Error || Reader.Error;

pub fn init(allocator: Allocator, reader: *Reader, options: Options) InitError!Table {
    var buf: [32]u8 = undefined;
    try reader.readSliceAll(&buf);

    const last_update = Date{
        .year = @as(u16, @intCast(buf[1])),
        .month = @as(u4, @intCast(buf[2])),
        .day = @as(u5, @intCast(buf[3])),
    };
    const number_of_records = std.mem.readVarInt(u32, buf[4..8], .little);
    const position_of_first_data_record = std.mem.readVarInt(u16, buf[8..10], .little);
    const length_of_one_data_record = std.mem.readVarInt(u16, buf[10..12], .little);

    const field_count = (position_of_first_data_record - 296) / 32;
    var fields = std.StringArrayHashMap(Field).init(allocator);

    const field_raw = try allocator.alloc(u8, field_count * 32);
    defer allocator.free(field_raw);
    try reader.readSliceAll(field_raw);
    try reader.discardAll(position_of_first_data_record - reader.seek);

    var i: usize = 0;
    while (i < field_count) : (i += 1) {
        const field_buf = field_raw[i * 32 .. (i * 32) + 32];

        const name = try allocator.dupe(u8, field_buf[0..10]);
        const displacement = std.mem.readVarInt(u32, field_buf[12..16], .little);

        const field = Field{
            .name = name,
            .type = @enumFromInt(field_buf[11]),
            .displacement_in_record = displacement,
            .length = field_buf[16],
            .number_of_decimal_places = field_buf[17],
        };

        try fields.put(std.mem.trimRight(u8, field.name, &[_]u8{0}), field);
    }

    return .{
        .last_update = last_update,
        .number_of_records = number_of_records,
        .position_of_first_data_record = position_of_first_data_record,
        .length_of_one_data_record = length_of_one_data_record,
        .fields = fields,
        .options = options,
        .reader = reader,
    };
}

pub fn deinit(self: *Table, allocator: Allocator) void {
    var it = self.fields.iterator();

    while (it.next()) |field| {
        allocator.free(field.value_ptr.name);
    }

    self.fields.deinit();
}

pub fn iter(self: *Table, allocator: Allocator) Allocator.Error!Iterator {
    return Iterator.init(allocator, self);
}

pub fn structIter(self: *Table, gpa: Allocator, T: type) Allocator.Error!StructIterator(T) {
    return StructIterator(T).init(gpa, self);
}
