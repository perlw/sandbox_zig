const c = @cImport({
    @cDefine("MAKEINTRESOURCE", "MAKEINTRESOURCEA");
    @cDefine("__MSABI_LONG(x)", "(long)(x)");
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cInclude("windows.h");
});

const std = @import("std");

const forzaprotocol = @import("game/forzaprotocol");
const graphics = @import("game/graphics");
const Bitmap = graphics.bitmap.Bitmap;
const Application = @import("./game.zig").Application;

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

const Backbuffer = struct {
    memory: ?*anyopaque = null, // Always 32-bit, memory order: XX RR GG BB | 03 02 01 00
    bitmapInfo: c.BITMAPINFO = undefined,
    width: u32 = 0,
    height: u32 = 0,
    bps: u32 = 0,
    pitch: u32 = 0,

    pub fn init(width: u32, height: u32) Backbuffer {
        var self = Backbuffer{};

        self.resizeBackbuffer(width, height);

        std.log.debug("{}", .{self});

        return self;
    }

    pub fn deinit(self: *Backbuffer) void {
        if (self.memory != null) {
            _ = c.VirtualFree(self.memory, 0, c.MEM_RELEASE);
        }
    }

    pub fn resizeBackbuffer(self: *Backbuffer, width: u32, height: u32) void {
        if (self.memory != null) {
            _ = c.VirtualFree(self.memory, 0, c.MEM_RELEASE);
        }

        self.width = width;
        self.height = height;
        self.bps = 4;
        self.pitch = self.width * self.height;

        self.bitmapInfo.bmiHeader = .{
            .biSize = @sizeOf(@TypeOf(self.bitmapInfo.bmiHeader)),
            .biWidth = @intCast(c_long, self.width),
            .biHeight = -@intCast(c_long, self.height),
            .biPlanes = 1,
            .biBitCount = 32,
            .biCompression = c.BI_RGB,

            .biSizeImage = 0,
            .biXPelsPerMeter = 0,
            .biYPelsPerMeter = 0,
            .biClrUsed = 0,
            .biClrImportant = 0,
        };

        self.memory = c.VirtualAlloc(null, self.bps * self.pitch, c.MEM_RESERVE | c.MEM_COMMIT, c.PAGE_READWRITE);
    }
};

pub fn main() !void {
    const hinstance = c.GetModuleHandleA(null);

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
    defer _ = c.DestroyWindow(window);

    std.log.info("All your codebase are belong to us.", .{});

    //   const win32 = std.os.windows;
    //   const wsa = win32.ws2_32;
    //   const wsa_data = try win32.WSAStartup(2, 2);
    //   defer win32.WSACleanup() catch unreachable;
    //   _ = wsa_data;
    //
    //   var addrinfo: *wsa.addrinfo = undefined;
    //   var hints = std.mem.zeroInit(wsa.addrinfo, .{
    //       .family = wsa.AF.INET,
    //       .socktype = wsa.SOCK.DGRAM,
    //       .protocol = wsa.IPPROTO.UDP,
    //   });
    //   std.log.debug("hints {}", .{hints});
    //
    //   switch (wsa.getaddrinfo("192.168.1.83", "13337", &hints, &addrinfo)) {
    //       0 => {},
    //       else => |err_int| switch (@intToEnum(wsa.WinsockError, @intCast(u16, err_int))) {
    //           else => |err| return win32.unexpectedWSAError(err),
    //       },
    //   }
    //   defer wsa.freeaddrinfo(addrinfo);
    //
    //   std.log.debug("addrinfo {}", .{addrinfo});
    //   var socket: wsa.SOCKET = wsa.INVALID_SOCKET;
    //   socket = wsa.socket(addrinfo.*.family, addrinfo.*.socktype, addrinfo.*.protocol);
    //   if (socket == wsa.INVALID_SOCKET) {
    //       std.log.err("INVALID_SOCKET", .{});
    //       return;
    //   }
    //   defer _ = wsa.closesocket(socket);
    //   if (wsa.bind(socket, addrinfo.*.addr.?, @intCast(i32, addrinfo.*.addrlen)) == wsa.SOCKET_ERROR) {
    //       std.log.err("SOCKET_ERROR", .{});
    //       return;
    //   }
    //   defer _ = wsa.shutdown(socket, wsa.SD_RECEIVE);
    //
    //   var buffer: [512]u8 = undefined;
    //   while (true) {
    //       var read_num = wsa.recv(socket, &buffer, buffer.len, 0);
    //       _ = read_num;
    //       //std.log.debug("got data! {} bytes", .{read_num});
    //       //std.log.debug("data: {any}", .{buffer[0..@intCast(usize, read_num)]});
    //
    //       const p = @ptrCast(*forzaprotocol.Packet, &buffer);
    //       // std.log.debug("cast: {}", .{p});
    //       std.log.debug("rpm: {}", .{@floatToInt(i32, p.*.current_engine_rpm)});
    //   }

    var backbuffer = Backbuffer.init(1280, 720);
    defer backbuffer.deinit();

    var app = Application.init();
    defer app.deinit();

    var hitF1 = false;
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
                    } else if (message.message == c.WM_KEYUP and message.wParam == c.VK_F1) {
                        hitF1 = true;
                    }
                },

                else => {
                    _ = c.TranslateMessage(&message);
                    _ = c.DispatchMessageA(&message);
                },
            }
        }

        var memory = @ptrCast([*c]u32, @alignCast(@alignOf(*u32), backbuffer.memory))[0..backbuffer.pitch];
        var screenBuffer = Bitmap{
            .memory = memory,
            .width = backbuffer.width,
            .height = backbuffer.height,
        };
        app.updateAndRender(&screenBuffer, hitF1);
        hitF1 = false;
        _ = hitF1;

        // TODO: Take ratio from actual resolution.
        var clientRect: c.RECT = undefined;
        _ = c.GetClientRect(window, &clientRect);
        const dimWidth = clientRect.right - clientRect.left;
        const dimHeight = clientRect.bottom - clientRect.top;
        const ratio: f32 = 16.0 / 9.0;
        const fixedWidth = @floatToInt(c_long, (@intToFloat(f32, dimHeight) * ratio));
        const offsetX = @divTrunc(dimWidth - fixedWidth, 2);

        const dc = c.GetDC(window);
        if (fixedWidth != dimWidth) {
            _ = c.PatBlt(dc, 0, 0, offsetX, dimHeight, c.BLACKNESS);
            _ = c.PatBlt(dc, dimWidth - offsetX, 0, offsetX, dimHeight, c.BLACKNESS);
        }
        _ = c.StretchDIBits(
            dc,
            offsetX,
            0,
            fixedWidth,
            dimHeight,
            0,
            0,
            @intCast(c_int, backbuffer.width),
            @intCast(c_int, backbuffer.height),
            backbuffer.memory,
            &backbuffer.bitmapInfo,
            c.DIB_RGB_COLORS,
            c.SRCCOPY,
        );
        _ = c.ReleaseDC(window, dc);
    }
}
