const std = @import("std");

const c = @cImport({
    @cDefine("MAKEINTRESOURCE", "MAKEINTRESOURCEA");
    @cDefine("__MSABI_LONG(x)", "(long)(x)");
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cInclude("windows.h");
});

const forzaprotocol = @import("game/forzaprotocol");

var global_is_running = true;

export fn windowProc(window: c.HWND, message: c.UINT, wparam: c.WPARAM, lparam: c.LPARAM) c.LRESULT {
    return switch (message) {
        c.WM_DESTROY => blk: {
            global_is_running = false;
            c.OutputDebugStringA("WM_DESTROY\n");
            break :blk 0;
        },

        c.WM_CLOSE => blk: {
            global_is_running = false;
            c.OutputDebugStringA("WM_CLOSE\n");
            break :blk 0;
        },

        else => c.DefWindowProcA(window, message, wparam, lparam),
    };
}

const window_class_name = "zigwin32platform";

pub fn main() !void {
    const hinstance = c.GetModuleHandleA(undefined);

    const window_class = c.WNDCLASSA{
        .style = c.CS_OWNDC | c.CS_HREDRAW | c.CS_VREDRAW,
        .lpfnWndProc = windowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hinstance,
        .hIcon = 0,
        .hCursor = c.LoadCursorA(hinstance, c.IDC_ARROW),
        .hbrBackground = 0,
        .lpszMenuName = 0,
        .lpszClassName = window_class_name,
    };
    if (c.RegisterClassA(&window_class) == 0) {
        c.OutputDebugStringA("could not register class\n");
    }

    var wsize = c.RECT{
        .left = 0,
        .top = 0,
        .right = 1280,
        .bottom = 720,
    };
    _ = c.AdjustWindowRect(&wsize, c.WS_OVERLAPPEDWINDOW, c.FALSE);
    std.log.debug("Adjusted window size to {}x{}", .{ wsize.right - wsize.left, wsize.bottom - wsize.top });

    const window = c.CreateWindowExA(
        0,
        window_class_name,
        "zig-lang hello winapi",
        c.WS_OVERLAPPEDWINDOW | c.WS_VISIBLE,
        c.CW_USEDEFAULT,
        c.CW_USEDEFAULT,
        wsize.right - wsize.left,
        wsize.bottom - wsize.top,
        null,
        null,
        hinstance,
        null,
    );
    if (window == null) {
        c.OutputDebugStringA("could not create window\n");
    }

    std.log.info("All your codebase are belong to us.", .{});

    const win32 = std.os.windows;
    const wsa = win32.ws2_32;
    const wsa_data = try win32.WSAStartup(2, 2);
    defer win32.WSACleanup() catch unreachable;
    _ = wsa_data;

    var addrinfo: *wsa.addrinfo = undefined;
    var hints = std.mem.zeroInit(wsa.addrinfo, .{
        .family = wsa.AF_INET,
        .socktype = wsa.SOCK_DGRAM,
        .protocol = wsa.IPPROTO_UDP,
    });
    std.log.debug("hints {}", .{hints});

    switch (wsa.getaddrinfo("192.168.1.83", "13337", &hints, &addrinfo)) {
        0 => {},
        else => |err_int| switch (@intToEnum(wsa.WinsockError, @intCast(u16, err_int))) {
            else => |err| return win32.unexpectedWSAError(err),
        },
    }
    defer wsa.freeaddrinfo(addrinfo);

    std.log.debug("addrinfo {}", .{addrinfo});
    var socket: wsa.SOCKET = wsa.INVALID_SOCKET;
    socket = wsa.socket(addrinfo.*.family, addrinfo.*.socktype, addrinfo.*.protocol);
    if (socket == wsa.INVALID_SOCKET) {
        std.log.err("INVALID_SOCKET", .{});
        return;
    }
    defer _ = wsa.closesocket(socket);
    if (wsa.bind(socket, addrinfo.*.addr.?, @intCast(i32, addrinfo.*.addrlen)) == wsa.SOCKET_ERROR) {
        std.log.err("SOCKET_ERROR", .{});
        return;
    }
    defer _ = wsa.shutdown(socket, wsa.SD_RECEIVE);

    var buffer: [512]u8 = undefined;
    while (true) {
        var read_num = wsa.recv(socket, &buffer, buffer.len, 0);
        _ = read_num;
        //std.log.debug("got data! {} bytes", .{read_num});
        //std.log.debug("data: {any}", .{buffer[0..@intCast(usize, read_num)]});

        const p = @ptrCast(*forzaprotocol.Packet, &buffer);
        // std.log.debug("cast: {}", .{p});
        std.log.debug("rpm: {}", .{@floatToInt(i32, p.*.current_engine_rpm)});
    }

    while (global_is_running) {
        var message: c.MSG = undefined;
        while (c.PeekMessageA(&message, window, 0, 0, c.PM_REMOVE) != 0) {
            switch (message.message) {
                c.WM_QUIT => {
                    global_is_running = false;
                },

                c.WM_SYSKEYDOWN, c.WM_SYSKEYUP, c.WM_KEYDOWN, c.WM_KEYUP => {
                    if (message.wParam == c.VK_ESCAPE) {
                        global_is_running = false;
                    }
                },

                else => {
                    _ = c.TranslateMessage(&message);
                    _ = c.DispatchMessageA(&message);
                },
            }
        }
    }
}
