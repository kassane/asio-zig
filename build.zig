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
    if (target.result.os.tag == .windows)
        buildExe(b, "stream-c", "examples/stream.c", .{
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
        .root_source_file = b.path("examples/test.zig"),
    });
    unit_test.root_module.omit_frame_pointer = false;
    unit_test.root_module.addIncludePath(b.path("include"));
    unit_test.root_module.linkLibrary(asio_c);
    if (unit_test.rootModuleTarget().os.tag == .windows) {
        unit_test.want_lto = false;
        unit_test.root_module.linkSystemLibrary("ws2_32", .{});
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
    exe.root_module.omit_frame_pointer = false;
    exe.root_module.addCSourceFile(.{ .file = b.path(filepath), .flags = cxxflags });
    exe.root_module.addIncludePath(b.path("include"));
    exe.root_module.linkLibrary(asio_c);

    if (exe.rootModuleTarget().os.tag == .windows) {
        exe.want_lto = false;
        exe.root_module.linkSystemLibrary("ws2_32", .{});
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

fn buildCAsio(b: *std.Build, info: BuildInfo) *std.Build.Step.Compile {
    const libasio_dep = b.dependency("asio", .{
        .target = info.target,
        .optimize = info.optimize,
    });
    const libasio = libasio_dep.artifact("asio");

    const lib = b.addStaticLibrary(.{
        .name = "asio_zig",
        .target = info.target,
        .optimize = info.optimize,
    });
    if (info.optimize == .Debug)
        lib.root_module.addCMacro("ASIO_ENABLE_HANDLER_TRACKING", "1");
    if (lib.rootModuleTarget().os.tag == .windows)
        lib.root_module.addCMacro("_WIN32_WINDOWS", "");
    lib.root_module.addIncludePath(b.path("include"));
    for (libasio.root_module.include_dirs.items) |include| {
        lib.root_module.include_dirs.append(b.allocator, include) catch {};
    }
    lib.root_module.addCSourceFile(.{ .file = b.path("src/asio_wrapper.cpp"), .flags = cxxflags });
    lib.root_module.linkLibrary(libasio);
    if (lib.rootModuleTarget().abi == .msvc)
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
    target: std.Build.ResolvedTarget,
};
