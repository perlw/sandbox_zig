const std = @import("std");

const c = @cImport({
    @cInclude("xcb/xcb.h");
    @cInclude("xcb/xcb_errors.h");
    @cInclude("malloc.h");
});

var globalIsRunning = true;

pub fn main() !void {
    var conn = c.xcb_connect(null, null);
    if (conn == null) {
        std.log.err("could not grab xcb connection", .{});
        std.os.exit(1);
    }
    defer c.xcb_disconnect(conn);
    var screen = c.xcb_setup_roots_iterator(c.xcb_get_setup(conn)).data;

    var mask: u32 = 0;
    var values: [2]u32 = undefined;

    const window = c.xcb_generate_id(conn);
    mask = c.XCB_CW_EVENT_MASK;
    values[0] = c.XCB_EVENT_MASK_EXPOSURE | c.XCB_EVENT_MASK_KEY_PRESS | c.XCB_EVENT_MASK_KEY_RELEASE;
    _ = c.xcb_create_window(conn, c.XCB_COPY_FROM_PARENT, window, screen.*.root, 0, 0, 1280, 720, 10, c.XCB_WINDOW_CLASS_INPUT_OUTPUT, screen.*.root_visual, mask, &values);
    defer _ = c.xcb_destroy_window(conn, window);

    // NOTE: Make sure we get the close window event (when letting decorations close the window etc).
    const protocolReply = c.xcb_intern_atom_reply(conn, c.xcb_intern_atom(conn, 1, 12, "WM_PROTOCOLS"), 0);
    const deleteWindowReply = c.xcb_intern_atom_reply(conn, c.xcb_intern_atom(conn, 0, 16, "WM_DELETE_WINDOW"), 0);
    _ = c.xcb_change_property(conn, c.XCB_PROP_MODE_REPLACE, window, protocolReply.*.atom, c.XCB_ATOM_ATOM, 32, 1, &deleteWindowReply.*.atom);

    // NOTE: Map window to screen.
    _ = c.xcb_map_window(conn, window);
    _ = c.xcb_flush(conn);

    std.log.info("All your codebase are belong to us.", .{});

    while (globalIsRunning) {
        var e = c.xcb_poll_for_event(conn);
        while (e != null) : (e = c.xcb_poll_for_event(conn)) {
            switch (e.*.response_type & ~@intCast(u8, 0x80)) {
                0 => {
                    const err = @ptrCast(*c.xcb_generic_error_t, e);
                    var errCtx: ?*c.xcb_errors_context_t = null;
                    _ = c.xcb_errors_context_new(conn, &errCtx);
                    defer c.xcb_errors_context_free(errCtx);

                    var major = c.xcb_errors_get_name_for_major_code(errCtx, err.*.major_code);
                    var minor = c.xcb_errors_get_name_for_minor_code(errCtx, err.*.major_code, err.*.minor_code);
                    var extension: ?*u8 = null;
                    var errMsg = c.xcb_errors_get_name_for_error(errCtx, err.*.error_code, &extension);
                    std.log.err("XCB Error: {s}:{s}, {s}:{s}, resource {} sequence {}", .{ errMsg, extension, major, minor, err.*.resource_id, err.*.sequence });
                },

                c.XCB_EXPOSE => {
                    std.log.debug("XCB_EXPOSE", .{});
                },

                c.XCB_KEY_PRESS, c.XCB_KEY_RELEASE => {
                    std.log.debug("XCB_KEY_PRESS/RELEASE", .{});

                    // if (e.*.response_type == c.XCB_KEY_PRESS) {
                    //}
                },

                c.XCB_CLIENT_MESSAGE => {
                    std.log.debug("XCB_CLIENT_MESSAGE", .{});
                    const evt = @ptrCast(*c.xcb_client_message_event_t, e);
                    if (evt.*.data.data32[0] == deleteWindowReply.*.atom) {
                        globalIsRunning = false;
                    }
                },

                else => {},
            }

            c.free(e);
        }
        _ = c.xcb_flush(conn);
    }
}
