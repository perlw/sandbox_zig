const std = @import("std");

pub const Bitmap = struct {
    allocator: std.mem.Allocator = undefined,
    memory: []u32,
    width: u32,
    height: u32,

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) !Bitmap {
        return Bitmap{
            .allocator = allocator,
            .memory = try allocator.alloc(u32, width * height),
            .width = width,
            .height = height,
        };
    }

    pub fn deinit(self: *Bitmap) void {
        self.allocator.free(self.memory);
    }
};
