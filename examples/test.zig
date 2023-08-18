const std = @import("std");
const testing = std.testing;
const asio = @cImport(@cInclude("asio_wrapper.h"));

test "Semantic Analyzer" {
    testing.refAllDeclsRecursive(@This());
}
test "Task runner" {
    const num_cpus = try std.Thread.getCpuCount();

    const handle: asio.AsioWrapperHandle = asio.asio_init(num_cpus);

    asio.asio_run(handle);
    defer asio.asio_destroy(handle);

    asio.asio_post_strand(handle, &taskHello, @as(?*anyopaque, @ptrFromInt(@intFromPtr("Hello from task 1"))));

    std.time.sleep(10000);
    asio.asio_stop(handle);
}

test "Fibonacci" {
    const handle: asio.AsioWrapperHandle = asio.asio_init(asio.get_maxCPU());

    asio.asio_run(handle);
    defer asio.asio_destroy(handle);
    const values = [_]usize{
        10, 20, 30, // fast
        //40, 50, 60, // slow
    };
    for (0..values.len) |i| {
        asio.asio_post_pool(handle, &fibTask, @as(?*anyopaque, @ptrFromInt(@intFromPtr(&values[i]))));
    }
}

fn taskHello(arg: ?*anyopaque) callconv(.C) void {
    std.debug.print("Task 1:\n{s}\n", .{@as([*:0]const u8, @ptrCast(arg))});
}

fn fibTask(arg: ?*anyopaque) callconv(.C) void {
    const n = @as(*usize, @ptrCast(@alignCast(arg))).*;
    std.debug.print("Fibonacci ({}): {}\n", .{ n, fibonacci(n) });
}
fn fibonacci(index: usize) usize {
    if (index < 2) return index;
    return fibonacci(index - 1) + fibonacci(index - 2);
}
