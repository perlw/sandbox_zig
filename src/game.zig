const std = @import("std");

const graphics = @import("game/graphics");
const Bitmap = graphics.bitmap.Bitmap;

const Effect = enum(u32) {
    Xor = 0,
    Plasma = 1,
};

pub const Application = struct {
    timestep: u32 = 0,
    effectNum: u32 = 0,
    palette: [768]u8 = [_]u8{0} ** (256 * 3),
    colors: u8 = 255,

    pub fn init() Application {
        var self = Application{};

        {
            var i: u32 = 0;
            while (i < 256) : (i += 1) {
                const fi = @intToFloat(f32, i);
                self.palette[(i * 3) + 0] = @floatToInt(u8, @mod(128.0 + (128.0 * @sin(std.math.pi * (fi / 16.0))), 256.0));
                self.palette[(i * 3) + 1] = @floatToInt(u8, @mod(128.0 + (128.0 * @sin(std.math.pi * (fi / 128.0))), 256.0));
                self.palette[(i * 3) + 2] = 0;
            }
        }

        return self;
    }

    pub fn deinit(self: *Application) void {
        _ = self;
    }

    pub fn drawXor(self: *Application, screenBuffer: *Bitmap) void {
        var y: u32 = 0;
        while (y < screenBuffer.height) : (y += 1) {
            var x: u32 = 0;
            while (x < screenBuffer.width) : (x += 1) {
                const i = (y * screenBuffer.width) + x;

                const col = ((x + self.timestep) ^ (y + self.timestep)) % 256;
                screenBuffer.memory[i] = (0xff << 24) + (col << 16) + (col << 8) + col;
            }
        }
    }

    pub fn drawPlasma(self: *Application, screenBuffer: *Bitmap) void {
        var y: u32 = 0;
        while (y < screenBuffer.height) : (y += 1) {
            var x: u32 = 0;
            while (x < screenBuffer.width) : (x += 1) {
                const i = (y * screenBuffer.width) + x;

                const fx = @intToFloat(f32, x);
                const fy = @intToFloat(f32, y);

                const palIndex = ((@floatToInt(u8, @mod((128.0 + (128.0 * @sin(fx / 32.0))) + (128.0 + (128.0 * @sin(fy / 32.0))) / 2.0, 256.0)) + self.timestep) % 256) % self.colors;
                const color = self.palette[palIndex * 3 .. (palIndex * 3) + 3];

                screenBuffer.memory[i] = (0xff << 24) + (@intCast(u32, color[0]) << 16) + (@intCast(u32, color[1]) << 8) + @intCast(u32, color[2]);
            }
        }
    }

    pub fn updateAndRender(self: *Application, screenBuffer: *Bitmap, toggled: bool) void {
        if (toggled) {
            self.effectNum = if (self.effectNum < 1) self.effectNum + 1 else 0;
            std.log.info("Set effect to: {}", .{@intToEnum(Effect, self.effectNum)});
        }

        switch (self.effectNum) {
            0 => self.drawXor(screenBuffer),
            1 => self.drawPlasma(screenBuffer),
            else => {},
        }

        self.timestep += 2;
    }
};
