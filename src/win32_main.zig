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
        .lpszClassName = "ziggerswin32platform",
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
    std.log.debug("Adjusted window size to {}x{}", .{wSize.right-wSize.left,wSize.bottom-wSize.top});

    const window = c.CreateWindowExA(
        0,
        "ziggerswin32platform",
        "zig-lang hello winapi",
        c.WS_OVERLAPPEDWINDOW | c.WS_VISIBLE,
        c.CW_USEDEFAULT,
        c.CW_USEDEFAULT,
        wSize.right-wSize.left,
        wSize.bottom-wSize.top,
        null,
        null,
        hInstance,
        null,
    );
    if (window == null) {
        c.OutputDebugStringA("could not create window\n");
    }

    std.log.info("All your codebase are belong to us.", .{});

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
