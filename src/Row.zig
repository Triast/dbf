const std = @import("std");
const Date = @import("Date.zig");
const Table = @import("Table.zig");
const Iterator = @import("Iterator.zig");

const Row = @This();

table: *Table,
buffer: []const u8,
index: u32,

pub fn getByFieldIndex(self: Row, comptime T: type, field_index: u8) !T {
    const field = self.table.fields.values()[field_index];
    return self.get(T, field);
}

pub fn getByFieldName(self: Row, comptime T: type, field_name: []const u8) !T {
    const field = self.table.fields.get(field_name) orelse return error.FieldNameNotFound;
    return self.get(T, field);
}

pub fn get(self: Row, comptime T: type, field: Table.Field) !T {
    const start = field.displacement_in_record;
    const end = start + field.length;

    switch (T) {
        []const u8 => {
            const string = std.mem.trimEnd(u8, self.buffer[start..end], &[_]u8{0});

            if (self.table.options.trim_strings) return std.mem.trim(u8, string, " ");
            return string;
        },
        u8 => {
            if (field.type == .numeric and field.number_of_decimal_places == 0) {
                const int_raw = std.mem.trim(u8, self.buffer[start..end], " ");

                if (int_raw.len == 0) return 0;

                return std.fmt.parseInt(T, int_raw, 10);
            }

            return self.buffer[start];
        },
        u16, u32, u64 => {
            if (field.type == .numeric and field.number_of_decimal_places == 0) {
                const int_raw = std.mem.trim(u8, self.buffer[start..end], " ");

                if (int_raw.len == 0) return 0;

                return std.fmt.parseInt(T, int_raw, 10);
            }
            return std.mem.readVarInt(T, self.buffer[start..end], .little);
        },
        f16, f32, f64, f80, f128 => {
            const float_raw = std.mem.trim(u8, self.buffer[start..end], " ");

            if (float_raw.len == 0) return 0.0;

            return std.fmt.parseFloat(T, std.mem.trim(u8, float_raw, " "));
        },
        ?Date => return if (!std.ascii.eqlIgnoreCase(self.buffer[start..end], " " ** 8)) Date{
            .year = try std.fmt.parseInt(u16, self.buffer[start .. start + 4], 10),
            .month = try std.fmt.parseInt(u4, self.buffer[start + 4 .. start + 6], 10),
            .day = try std.fmt.parseInt(u5, self.buffer[start + 6 .. end], 10),
        } else null,
        bool => return self.buffer[start] == 'T',
        ?bool => {
            if (self.buffer[start] == 'T') return true;
            if (self.buffer[start] == 'F') return false;
            return null;
        },
        else => @compileError("Function for type " ++ @typeName(T) ++ " not implemented."),
    }
}

pub fn isDeleted(self: Row) bool {
    return self.buffer[0] == '*';
}

pub fn recno(self: Row) u32 {
    return self.index;
}
