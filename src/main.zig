const std = @import("std");
const TextFileReader = @import("textFileReader.zig").TextFileReader;
const db = @import("db.zig");
// const  = std.fs;
const print = std.debug.print;

pub const pg_stderr_tls = true;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();

    const file_name = args.next() orelse {
        print("Usage: <program> <file>\n", .{});
        return;
    };

    // const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    // defer file.close();

    var tr = try TextFileReader.init(file_name, allocator, 1024);
    defer tr.deinit();

    var db_pool = try db.Db.init(allocator);
    defer db_pool.deinit();

    const header = "SERVICE,DATE,START TIME,END TIME,USAGE,UNITS";
    var isDataLine = false;
    while (try tr.readline()) |line| {
        if (isDataLine) {
            // Process data line
            var it = std.mem.tokenizeScalar(u8, line, ',');
            const service = it.next() orelse "";
            if (service.len == 0) {
                // Empty service indicates end of data
                break;
            }
            const date = it.next() orelse "";
            const start_time = it.next() orelse "";
            const end_time = it.next() orelse "";
            const usage = it.next() orelse "";
            const usage_int = try std.fmt.parseInt(u32, usage, 10);
            const units = it.next() orelse "";

            // print("Service: {s}, Date: {s}, Start: {s}, End: {s}, Usage: {d}, Units: {s}\n", .{ service, date, start_time, end_time, usage_int, units });

            db_pool.insert_record(.{ .service = service, .date = date, .start_time = start_time, .end_time = end_time, .usage = usage_int, .units = units }) catch {
                print("Failed to insert record into database\n", .{});
            };

            continue;
        }
        if (std.mem.startsWith(u8, line, header)) {
            isDataLine = true;
            continue;
        }
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
