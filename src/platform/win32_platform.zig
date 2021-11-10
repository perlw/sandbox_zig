const std = @import("std");

const c = @cImport({
    @cDefine("MAKEINTRESOURCE", "MAKEINTRESOURCEA");
    @cDefine("__MSABI_LONG(x)", "(long)(x)");
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cInclude("windows.h");
});

var globalIsRunning = true;

export fn WindowProc(window: c.HWND, message: c.UINT, wParam: c.WPARAM, lParam: c.LPARAM) c.LRESULT {
    return switch (message) {
        c.WM_DESTROY => blk: {
            globalIsRunning = false;
            c.OutputDebugStringA("WM_DESTROY\n");
            break :blk 0;
        },

        c.WM_CLOSE => blk: {
            globalIsRunning = false;
            c.OutputDebugStringA("WM_CLOSE\n");
            break :blk 0;
        },

        else => c.DefWindowProcA(window, message, wParam, lParam),
    };
}

const windowClassName = "zigwin32platform";

pub fn main() !void {
    const hInstance = c.GetModuleHandleA(undefined);

    const windowClass = c.WNDCLASSA{
        .style = c.CS_OWNDC | c.CS_HREDRAW | c.CS_VREDRAW,
        .lpfnWndProc = WindowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = 0,
        .hCursor = c.LoadCursorA(hInstance, c.IDC_ARROW),
        .hbrBackground = 0,
        .lpszMenuName = 0,
        .lpszClassName = windowClassName,
    };
    if (c.RegisterClassA(&windowClass) == 0) {
        c.OutputDebugStringA("could not register class\n");
    }

    var wSize = c.RECT{
        .left = 0,
        .top = 0,
        .right = 1280,
        .bottom = 720,
    };
    _ = c.AdjustWindowRect(&wSize, c.WS_OVERLAPPEDWINDOW, c.FALSE);
    std.log.debug("Adjusted window size to {}x{}", .{ wSize.right - wSize.left, wSize.bottom - wSize.top });

    const window = c.CreateWindowExA(
        0,
        windowClassName,
        "zig-lang hello winapi",
        c.WS_OVERLAPPEDWINDOW | c.WS_VISIBLE,
        c.CW_USEDEFAULT,
        c.CW_USEDEFAULT,
        wSize.right - wSize.left,
        wSize.bottom - wSize.top,
        null,
        null,
        hInstance,
        null,
    );
    if (window == null) {
        c.OutputDebugStringA("could not create window\n");
    }

    std.log.info("All your codebase are belong to us.", .{});

    const win32 = std.os.windows;
    const wsa = win32.ws2_32;
    const wsaData = try win32.WSAStartup(2, 2);
    defer win32.WSACleanup() catch unreachable;

    var addrInfo: *wsa.addrinfo = undefined;
    var hints = std.mem.zeroInit(wsa.addrinfo, .{
        .family = wsa.AF_INET,
        .socktype = wsa.SOCK_DGRAM,
        .protocol = wsa.IPPROTO_UDP,
    });
    std.log.debug("hints {}", .{hints});

    switch (wsa.getaddrinfo("192.168.1.83", "13337", &hints, &addrInfo)) {
        0 => {},
        else => |err_int| switch (@intToEnum(wsa.WinsockError, @intCast(u16, err_int))) {
            else => |err| return win32.unexpectedWSAError(err),
        },
    }
    defer wsa.freeaddrinfo(addrInfo);

    std.log.debug("addrinfo {}", .{addrInfo});
    var socket: wsa.SOCKET = wsa.INVALID_SOCKET;
    socket = wsa.socket(addrInfo.*.family, addrInfo.*.socktype, addrInfo.*.protocol);
    if (socket == wsa.INVALID_SOCKET) {
        std.log.err("INVALID_SOCKET", .{});
        return;
    }
    defer _ = wsa.closesocket(socket);
    if (wsa.bind(socket, addrInfo.*.addr.?, @intCast(i32, addrInfo.*.addrlen)) == wsa.SOCKET_ERROR) {
        std.log.err("SOCKET_ERROR", .{});
        return;
    }
    defer _ = wsa.shutdown(socket, wsa.SD_RECEIVE);

    // while (true) {
    var buffer: [512]u8 = undefined;
    var readNum = wsa.recv(socket, &buffer, buffer.len, 0);
    std.log.debug("got data! {} bytes", .{readNum});
    std.log.debug("data: {any}", .{buffer[0..@intCast(usize, readNum)]});
    // }

    while (globalIsRunning) {
        var message: c.MSG = undefined;
        while (c.PeekMessageA(&message, window, 0, 0, c.PM_REMOVE) != 0) {
            switch (message.message) {
                c.WM_QUIT => {
                    globalIsRunning = false;
                },

                c.WM_SYSKEYDOWN, c.WM_SYSKEYUP, c.WM_KEYDOWN, c.WM_KEYUP => {
                    if (message.wParam == c.VK_ESCAPE) {
                        globalIsRunning = false;
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
