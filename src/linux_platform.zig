const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("xcb/shm.h");
    @cInclude("xcb/xcb.h");
    @cInclude("xcb/xcb_errors.h");
    @cInclude("malloc.h");
    @cInclude("sys/shm.h");

    @cDefine("XK_MISCELLANY", "1");
    @cDefine("XK_LATIN1", "1");
    @cInclude("xcb/xcb_keysyms.h");
    @cInclude("X11/XKBlib.h");
    @cInclude("X11/keysymdef.h");
});

const std = @import("std");

const graphics = @import("game/graphics");
const Bitmap = graphics.bitmap.Bitmap;
const Application = @import("./game.zig").Application;

var global_is_running = true;

const Backbuffer = struct {
    connection: *c.xcb_connection_t,
    window: c.xcb_drawable_t,

    shmID: c_int = 0,
    shmSeg: c.xcb_shm_seg_t,
    pixmapID: c.xcb_pixmap_t,

    memory: *anyopaque = undefined, // Always 32-bit, memory order: XX RR GG BB | 03 02 01 00
    width: u32 = 0,
    height: u32 = 0,
    bps: u32 = 0,
    pitch: u32 = 0,

    pub fn init(connection: *c.xcb_connection_t, window: c.xcb_drawable_t, width: u32, height: u32) Backbuffer {
        var self = Backbuffer{
            .connection = connection,
            .window = window,
            .shmSeg = c.xcb_generate_id(connection),
            .pixmapID = c.xcb_generate_id(connection),
        };

        self.resizeBackbuffer(width, height);

        std.log.debug("{}", .{self});

        return self;
    }

    pub fn deinit(self: *Backbuffer) void {
        _ = c.xcb_shm_detach(self.connection, self.shmSeg);
        _ = c.shmctl(self.shmID, c.IPC_RMID, 0);
        _ = c.shmdt(self.memory);
        _ = c.xcb_free_pixmap(self.connection, self.pixmapID);
    }

    pub fn resizeBackbuffer(self: *Backbuffer, width: u32, height: u32) void {
        if (self.shmID != 0) {
            _ = c.xcb_shm_detach(self.connection, self.shmSeg);
            _ = c.shmctl(self.shmID, c.IPC_RMID, 0);
            _ = c.shmdt(self.memory);
            _ = c.xcb_free_pixmap(self.connection, self.pixmapID);
        }
        _ = c.xcb_flush(self.connection);

        self.width = width;
        self.height = height;
        self.bps = 4;
        self.pitch = self.width * self.height;

        self.shmID = c.shmget(c.IPC_PRIVATE, self.bps * self.pitch, c.IPC_CREAT | 0o600);
        self.memory = c.shmat(self.shmID, null, 0).?;

        _ = c.xcb_shm_attach(self.connection, self.shmSeg, @intCast(c_uint, self.shmID), 0);
        const screen = c.xcb_setup_roots_iterator(c.xcb_get_setup(self.connection)).data;
        _ = c.xcb_shm_create_pixmap(
            self.connection,
            self.pixmapID,
            self.window,
            @intCast(u16, self.width),
            @intCast(u16, self.height),
            screen.*.root_depth,
            self.shmSeg,
            0,
        );
    }
};

inline fn getClockValue() c.timespec {
    var tv: c.timespec = undefined;
    _ = c.clock_gettime(c.CLOCK_MONOTONIC_RAW, &tv);
    return tv;
}

inline fn getSecondsElapsed(start: c.timespec, end: c.timespec) f32 {
    return @intToFloat(f32, (end.tv_sec - start.tv_sec)) + (@intToFloat(f32, end.tv_nsec - start.tv_nsec) / 1000000000.0);
}

pub fn main() !void {
    const connection = c.xcb_connect(null, null);
    if (connection == null) {
        std.log.err("could not grab xcb connection", .{});
        std.os.exit(1);
    }
    defer c.xcb_disconnect(connection);
    const screen = c.xcb_setup_roots_iterator(c.xcb_get_setup(connection)).data;

    var mask: u32 = 0;
    var values: [2]u32 = undefined;

    const window = c.xcb_generate_id(connection);
    mask = c.XCB_CW_EVENT_MASK;
    values[0] = c.XCB_EVENT_MASK_EXPOSURE | c.XCB_EVENT_MASK_KEY_PRESS | c.XCB_EVENT_MASK_KEY_RELEASE;
    _ = c.xcb_create_window(
        connection,
        c.XCB_COPY_FROM_PARENT,
        window,
        screen.*.root,
        0,
        0,
        1280,
        720,
        10,
        c.XCB_WINDOW_CLASS_INPUT_OUTPUT,
        screen.*.root_visual,
        mask,
        &values,
    );
    defer _ = c.xcb_destroy_window(connection, window);

    const gcontext = c.xcb_generate_id(connection);
    _ = c.xcb_create_gc(connection, gcontext, window, 0, null);

    // NOTE: Make sure we get the close window event (when letting decorations close the window etc).
    const protocol_reply = c.xcb_intern_atom_reply(connection, c.xcb_intern_atom(connection, 1, 12, "WM_PROTOCOLS"), 0);
    const delete_window_reply = c.xcb_intern_atom_reply(connection, c.xcb_intern_atom(connection, 0, 16, "WM_DELETE_WINDOW"), 0);
    _ = c.xcb_change_property(connection, c.XCB_PROP_MODE_REPLACE, window, protocol_reply.*.atom, c.XCB_ATOM_ATOM, 32, 1, &delete_window_reply.*.atom);

    // NOTE: Map window to screen.
    _ = c.xcb_map_window(connection, window);
    _ = c.xcb_flush(connection);

    // NOTE: SHM Support.
    const reply = c.xcb_shm_query_version_reply(connection, c.xcb_shm_query_version(connection), null);
    if (reply == null or reply.*.shared_pixmaps == 0) {
        std.log.err("Shm error...", .{});
        return;
    }

    var backbuffer = Backbuffer.init(connection.?, window, 1280, 720);
    defer backbuffer.deinit();

    const shmCompletionEvent = c.xcb_get_extension_data(connection, &c.xcb_shm_id).*.first_event + c.XCB_SHM_COMPLETION;

    const keySyms = c.xcb_key_symbols_alloc(connection);
    defer c.xcb_key_symbols_free(keySyms);

    std.log.info("All your codebase are belong to us.", .{});

    var app = Application.init();
    defer app.deinit();

    const gameUpdateHz: f32 = 30.0;
    const targetSecondsPerFrame: f32 = 1.0 / gameUpdateHz;
    var lastCounter = getClockValue();

    var hitF1 = false;
    var readyToBlit = true;
    while (global_is_running) {
        var e = c.xcb_poll_for_event(connection);
        while (e != null) : (e = c.xcb_poll_for_event(connection)) {
            switch (e.*.response_type & ~@intCast(u8, 0x80)) {
                0 => {
                    const err = @ptrCast(*c.xcb_generic_error_t, e);
                    var err_ctx: ?*c.xcb_errors_context_t = null;
                    _ = c.xcb_errors_context_new(connection, &err_ctx);
                    defer c.xcb_errors_context_free(err_ctx);

                    const major = c.xcb_errors_get_name_for_major_code(err_ctx, err.*.major_code);
                    const minor = c.xcb_errors_get_name_for_minor_code(err_ctx, err.*.major_code, err.*.minor_code);
                    var extension: ?*u8 = null;
                    const err_msg = c.xcb_errors_get_name_for_error(err_ctx, err.*.error_code, &extension);
                    std.log.err("XCB Error: {s}:{s}, {s}:{s}, resource {} sequence {}", .{ err_msg, extension, major, minor, err.*.resource_id, err.*.sequence });
                },

                c.XCB_EXPOSE => {
                    std.log.debug("XCB_EXPOSE", .{});
                },

                c.XCB_KEY_PRESS, c.XCB_KEY_RELEASE => {
                    std.log.debug("XCB_KEY_PRESS/RELEASE", .{});
                    if (e.*.response_type == c.XCB_KEY_PRESS) {
                        const evt = @ptrCast(*c.xcb_key_press_event_t, e);
                        const keySym = c.xcb_key_press_lookup_keysym(keySyms, evt, 0);
                        std.log.debug("DOWN {}?={} or {}", .{ keySym, c.XK_Escape, c.XK_F1 });
                    } else if (e.*.response_type == c.XCB_KEY_RELEASE) {
                        const evt = @ptrCast(*c.xcb_key_press_event_t, e);
                        const keySym = c.xcb_key_press_lookup_keysym(keySyms, evt, 0);
                        std.log.debug("UP {}?={} or {}", .{ keySym, c.XK_Escape, c.XK_F1 });

                        if (keySym == c.XK_Escape) {
                            global_is_running = false;
                        } else if (keySym == c.XK_F1) {
                            hitF1 = true;
                        }
                    }
                },

                c.XCB_CLIENT_MESSAGE => {
                    std.log.debug("XCB_CLIENT_MESSAGE", .{});
                    const evt = @ptrCast(*c.xcb_client_message_event_t, e);
                    if (evt.*.data.data32[0] == delete_window_reply.*.atom) {
                        global_is_running = false;
                    }
                },

                else => {},
            }

            if (shmCompletionEvent == (e.*.response_type & ~@intCast(u8, 0x80))) {
                readyToBlit = true;
            }

            c.free(e);
        }

        const secondsElapsedPerFrame = getSecondsElapsed(lastCounter, getClockValue());
        if (secondsElapsedPerFrame < targetSecondsPerFrame) {
            const sleepMics = @floatToInt(c_uint, 1000000.0 * (targetSecondsPerFrame - secondsElapsedPerFrame));
            if (sleepMics > 0) {
                _ = c.usleep(sleepMics);
            }
        }
        const endCounter = getClockValue();
        const msPerFrame = 1000.0 * getSecondsElapsed(lastCounter, endCounter);
        lastCounter = endCounter;

        // TODO: Do this outside.
        var memory = @ptrCast([*c]u32, @alignCast(@alignOf(*u32), backbuffer.memory))[0..backbuffer.pitch];
        var screenBuffer = Bitmap{
            .memory = memory,
            .width = backbuffer.width,
            .height = backbuffer.height,
        };
        app.updateAndRender(&screenBuffer, hitF1, msPerFrame);
        hitF1 = false;

        if (readyToBlit) {
            readyToBlit = false;

            _ = c.xcb_shm_put_image(
                connection,
                window,
                gcontext,
                @intCast(u16, backbuffer.width), // src_x
                @intCast(u16, backbuffer.height), // src_y
                0, // dest_x
                0, // dest_y
                @intCast(u16, backbuffer.width), // src_width
                @intCast(u16, backbuffer.height), // src_height
                0,
                0,
                screen.*.root_depth,
                c.XCB_IMAGE_FORMAT_Z_PIXMAP,
                1,
                backbuffer.shmSeg,
                0,
            );

            _ = c.xcb_flush(connection);
        }
    }
}
