const std = @import("std");

const Bitmap = @import("./bitmap.zig").Bitmap;

pub const Application = struct {
    offset: u32 = 0,

    pub fn init() Application {
        return .{};
    }

    pub fn deinit(self: *Application) void {
        _ = self;
    }

    pub fn updateAndRender(self: *Application, screenBuffer: *Bitmap) void {
        var y: u32 = 0;
        while (y < screenBuffer.height) : (y += 1) {
            var x: u32 = 0;
            while (x < screenBuffer.width) : (x += 1) {
                const i = (y * screenBuffer.width) + x;

                const col = ((x + self.offset) ^ (y + self.offset)) % 256;
                screenBuffer.memory[i] = (0xff << 24) + (col << 16) + (col << 8) + col;
            }
        }
        self.offset += 1;
    }
};
