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

    // --------------------------------------------------
    const asio_c = buildCAsio(b, .{
        .target = target,
        .optimize = optimize,
    });

    const unit_test = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{
            .path = "examples/hello.zig",
        },
    });
    unit_test.addIncludePath("include");
    unit_test.linkLibrary(asio_c);
    if (target.isWindows())
        unit_test.linkSystemLibrary("ws2_32");
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
    exe.addCSourceFile(filepath, &.{
        "-Wall",
        "-Wextra",
        "-Werror",
    });
    exe.addIncludePath("include");
    exe.linkLibrary(asio_c);
    if (info.target.isWindows())
        exe.linkSystemLibrary("ws2_32");
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
        .name = "asio_c",
        .target = info.target,
        .optimize = info.optimize,
    });
    lib.addIncludePath("include");
    lib.addCSourceFile("src/asio_wrapper.cpp", &.{
        "-Wall",
        "-Wextra",
        "-Werror",
    });
    lib.linkLibrary(libasio);
    lib.installLibraryHeaders(libasio); // get copy asio include
    lib.linkLibCpp(); //llvm-libcxx
    return lib;
}

const BuildInfo = struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
};