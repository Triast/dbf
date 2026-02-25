const std = @import("std");
const Table = @import("Table.zig");
const Row = @import("Row.zig");
const Allocator = std.mem.Allocator;
const Reader = std.Io.Reader;

pub fn StructIterator(T: type) type {
    return struct {
        const Self = @This();

        table: *Table,
        buffer: []u8 = undefined,

        index: u32 = 0,

        pub fn init(gpa: Allocator, table: *Table) Allocator.Error!Self {
            const buf = try gpa.alloc(u8, table.length_of_one_data_record);

            return .{
                .table = table,
                .buffer = buf,
            };
        }

        pub fn deinit(self: Self, gpa: Allocator) void {
            gpa.free(self.buffer);
        }

        pub fn next(self: *Self) !?T {
            while (true) {
                if (self.index >= self.table.number_of_records) return null;

                self.table.reader.readSliceAll(self.buffer) catch |err| switch (err) {
                    error.EndOfStream => return null,
                    error.ReadFailed => return err,
                };

                self.index += 1;

                if (!self.table.options.ignore_deleted) break;
                if (self.buffer[0] != '*') break;
            }

            const row: Row = .{
                .table = self.table,
                .buffer = self.buffer,
                .index = self.index,
            };

            var value: T = undefined;

            switch (@typeInfo(T)) {
                .@"struct" => |info| {
                    inline for (info.fields) |field| {
                        @field(value, field.name) = try row.getByFieldName(field.type, comptimeUpperString(field.name));
                    }
                },
                else => @compileError("Expected struct type, found '" ++ @typeName(T) ++ "'"),
            }

            return value;
        }
    };
}

inline fn comptimeUpperString(comptime ascii_string: []const u8) *const [ascii_string.len:0]u8 {
    comptime {
        var buf: [ascii_string.len:0]u8 = undefined;
        _ = std.ascii.upperString(&buf, ascii_string);
        buf[buf.len] = 0;
        const final = buf;
        return &final;
    }
}
