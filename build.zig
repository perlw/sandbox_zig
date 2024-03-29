const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    var exe: *std.build.LibExeObjStep = undefined;
    switch (builtin.os.tag) {
        .windows => {
            exe = b.addExecutable("platform_win32", "src/win32_platform.zig");
            exe.linkSystemLibrary("c");
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("kernel32");
            exe.linkSystemLibrary("gdi32");
        },

        .linux => {
            exe = b.addExecutable("platform_linux", "src/linux_platform.zig");
            exe.linkSystemLibrary("c");
            exe.linkSystemLibrary("xcb");
            exe.linkSystemLibrary("xcb-shm");
            exe.linkSystemLibrary("xcb-keysyms");
            exe.linkSystemLibrary("xcb-errors");
            exe.linkSystemLibrary("X11");
        },

        else => {
            @compileError("Unknown OS target for build");
        },
    }
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("game/forzaprotocol", "src/forzaprotocol/index.zig");
    exe.addPackagePath("game/graphics", "src/graphics/index.zig");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
