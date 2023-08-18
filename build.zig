const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    buildExe(b, "hello-c", "examples/hello.c", .{
        .target = target,
        .optimize = optimize,
    });
    buildExe(b, "counter-c", "examples/counter.c", .{
        .target = target,
        .optimize = optimize,
    });
    buildExe(b, "fib-c", "examples/fib.c", .{
        .target = target,
        .optimize = optimize,
    });
    if (!target.isWindows()) buildExe(b, "stream-c", "examples/stream.c", .{
        .target = target,
        .optimize = optimize,
    });

    // --------------------------------------------------
    buildTest(b, .{
        .target = target,
        .optimize = optimize,
    });
}

fn buildTest(b: *std.Build, info: BuildInfo) void {
    const asio_c = buildCAsio(b, .{
        .target = info.target,
        .optimize = info.optimize,
    });

    const unit_test = b.addTest(.{
        .target = info.target,
        .optimize = info.optimize,
        .root_source_file = .{ .path = "examples/test.zig" },
    });
    unit_test.omit_frame_pointer = false;
    unit_test.addIncludePath(.{ .path = "include" });
    unit_test.linkLibrary(asio_c);
    if (info.target.isWindows()) {
        unit_test.want_lto = false;
        unit_test.linkSystemLibrary("ws2_32");
    }
    unit_test.linkLibC();

    const run_unit_tests = b.addRunArtifact(unit_test);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
fn buildExe(b: *std.Build, name: []const u8, filepath: []const u8, info: BuildInfo) void {
    const asio_c = buildCAsio(b, .{
        .target = info.target,
        .optimize = info.optimize,
    });

    const exe = b.addExecutable(.{
        .name = name,
        .target = info.target,
        .optimize = info.optimize,
    });
    exe.omit_frame_pointer = false;
    exe.addCSourceFile(.{ .file = .{ .path = filepath }, .flags = cxxflags });
    exe.addIncludePath(.{ .path = "include" });
    exe.linkLibrary(asio_c);

    if (info.target.isWindows()) {
        exe.want_lto = false;
        exe.linkSystemLibrary("ws2_32");
    }

    exe.linkLibC();

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(b.fmt("{s}", .{name}), b.fmt("Run the {s} app", .{name}));
    run_step.dependOn(&run_cmd.step);
}

fn buildCAsio(b: *std.Build, info: BuildInfo) *std.Build.CompileStep {
    const libasio_dep = b.dependency("asio", .{
        .target = info.target,
        .optimize = info.optimize,
    });
    const libasio = libasio_dep.artifact("asio");

    const lib = b.addStaticLibrary(.{
        .name = "asio_c",
        .target = info.target,
        .optimize = info.optimize,
    });
    if (lib.optimize == .Debug)
        lib.defineCMacro("ASIO_ENABLE_HANDLER_TRACKING", null);
    if (info.target.isWindows())
        lib.defineCMacro("_WIN32_WINDOWS", null);
    lib.addIncludePath(.{ .path = "include" });
    for (libasio.include_dirs.items) |include| {
        lib.include_dirs.append(include) catch {};
    }
    lib.addCSourceFile(.{ .file = .{ .path = "src/asio_wrapper.cpp" }, .flags = cxxflags });
    lib.linkLibrary(libasio);
    if (lib.target.getAbi() == .msvc)
        lib.linkLibC()
    else
        lib.linkLibCpp(); //llvm-libcxx
    return lib;
}

const cxxflags = &.{
    "-Wall",
    "-Wextra",
};
const BuildInfo = struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
};
