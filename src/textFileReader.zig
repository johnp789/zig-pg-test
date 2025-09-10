// modified from https://ziggit.dev/t/im-too-dumb-for-zigs-new-io-interface/11645/20
const std = @import("std");

pub const TextFileReader = struct {
    allocator: std.mem.Allocator,
    buffer: []u8,
    file: std.fs.File,
    reader: std.fs.File.Reader,

    pub fn init(allocator: std.mem.Allocator, filename: []const u8, linebuffer_size: usize) !TextFileReader {
        const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        const buf = try allocator.alloc(u8, linebuffer_size);
        return .{
            .allocator = allocator,
            .buffer = buf,
            .file = file,
            .reader = file.reader(buf),
        };
    }

    pub fn deinit(self: *TextFileReader) void {
        self.allocator.free(self.buffer);
        self.file.close();
    }

    pub fn readline(self: *TextFileReader) !?[]const u8 {
        const line = self.reader.interface.takeDelimiterExclusive('\n') catch |err|
            {
                return if (err == std.io.Reader.DelimiterError.EndOfStream) null else err;
            };
        return line;
    }
};
