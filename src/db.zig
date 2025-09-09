const std = @import("std");
const pg = @import("pg");

pub const Record = struct {
    service: []const u8,
    date: []const u8,
    start_time: []const u8,
    end_time: []const u8,
    usage: u32,
    units: []const u8,
};

pub const Db = struct {
    _allocator: std.mem.Allocator,
    _pool: ?*pg.Pool = null,
    _host: []const u8,
    _password: []const u8,

    pub fn init(allocator: std.mem.Allocator) !Db {
        const password = std.process.getEnvVarOwned(allocator, "PGPASSWORD") catch |err| (if (err == error.EnvironmentVariableNotFound) "password" else return err);
        errdefer allocator.free(password);
        const host = std.process.getEnvVarOwned(allocator, "PGHOST") catch |err| (if (err == error.EnvironmentVariableNotFound) "127.0.0.1" else return err);
        errdefer allocator.free(host);
        std.debug.print("Connecting to database at {s} with user 'postgres'\n", .{host});
        // Segfault happens right after this line.
        const _pool = try pg.Pool.init(allocator, .{
            .size = 5,
            .connect = .{
                .port = 5432,
                .host = host,
                .tls = .require,
                // .tls = .{ .verify_full = "postgres-test-server/certs/ca.crt" }, // hard-coded path to CA cert
            },
            .auth = .{
                .username = "postgres",
                .database = "postgres",
                .password = password,
                .timeout = 10_000,
            },
        });
        std.debug.print("Connected to database\n", .{});
        return Db{
            ._allocator = allocator,
            ._pool = _pool,
            ._host = host,
            ._password = password,
        };
    }

    pub fn deinit(self: *Db) void {
        if (self._pool) |pool| {
            pool.deinit();
            self._pool = null;
            self._allocator.free(self._password);
            self._allocator.free(self._host);
        }
    }

    pub fn insert_record(self: *Db, record: Record) !void {
        if (self._pool == null) {
            return error.PoolNotInitialized;
        }
        const pool = self._pool.?;
        const conn = try pool.acquire();
        defer conn.release();

        const query = "INSERT INTO usage_data (service, date, start_time, end_time, usage, units) VALUES ($1, $2, $3, $4, $5, $6)";
        _ = try conn.exec(query, .{ record.service, record.date, record.start_time, record.end_time, record.usage, record.units });
    }
};
