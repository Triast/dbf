const std = @import("std");

pub const Date = @import("Date.zig");
pub const Iterator = @import("Iterator.zig");
pub const Row = @import("Row.zig");
pub const Table = @import("Table.zig");

pub fn convertCp1251ToUtf8Buffer(bytes: []const u8, buf: []u8) !u16 {
    var buf_index: u16 = 0;
    for (bytes) |byte| {
        const codepoint: u21 = switch (byte) {
            0xC0...0xFF => @as(u21, byte) + 0x350,
            0xB9 => 0x2116,
            0xA8 => 0x401,
            0xB8 => 0x451,
            else => @as(u21, byte),
        };

        const bytes_written = try std.unicode.utf8Encode(codepoint, buf[buf_index..]);
        buf_index += bytes_written;
    }

    return buf_index;
}

pub fn convertUtf8ToCp1251(bytes: []const u8, buf: []u8) !usize {
    const view = try std.unicode.Utf8View.init(bytes);
    var it = view.iterator();

    var buf_index: usize = 0;
    while (it.nextCodepoint()) |codepoint| {
        const byte = switch (codepoint) {
            0x00...0x7f => @as(u8, @intCast(codepoint)),
            0xc0 + 0x350...0xff + 0x350 => @as(u8, @intCast(codepoint - 0x350)),
            0x2116 => 0xb9,
            0x401 => 0xa8,
            0x451 => 0xb8,
            else => return error.UnicodeCodepointConversionNotImplemented,
        };

        buf[buf_index] = byte;
        buf_index += 1;
    }

    return buf_index;
}
